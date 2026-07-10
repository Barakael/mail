#!/usr/bin/python3
"""Postfix content filter that appends the TERA corporate footer.

Wired into master.cf as the `footerfilter` pipe service and attached to the
authenticated submission services (587/465/588 + haproxy variants). Those
services have their milter disabled, so this filter runs BEFORE any DKIM
signing: it appends the footer, then reinjects the message with `sendmail`.
The reinjected message is signed by rspamd on the way out (sign_local=true),
so DKIM covers the footered body with a single valid signature.

Safety: on ANY error the ORIGINAL message is reinjected unchanged, so mail is
never lost or corrupted by this filter. Only if reinjection itself fails do we
return EX_TEMPFAIL so Postfix retries.
"""
import os
import sys
import subprocess
from email import policy
from email.parser import BytesParser

SENDMAIL = "/usr/sbin/sendmail"
DISCLAIMER_DIR = "/opt/postfix/conf/disclaimer"
# Mailcow runs Postfix from /opt/postfix/conf, but postdrop only authorizes the
# compiled-in default (/etc/postfix). Both share queue_directory=/var/spool/postfix,
# so reinjecting via the default config lands in the same queue the running
# instance picks up (where rspamd applies DKIM). Without this, postdrop refuses
# with "unauthorized configuration directory name: /opt/postfix/conf".
REINJECT_CONFIG = "/etc/postfix"
FLAG_HEADER = "X-Corporate-Footer"
FLAG_VALUE = "TERA"
SIGN_DOMAINS = ("ticketfasta.co.tz", "teratech.co.tz")

EX_TEMPFAIL = 75


def reinject(raw_bytes, args):
    """Hand the message back to Postfix for delivery."""
    env = dict(os.environ, MAIL_CONFIG=REINJECT_CONFIG)
    result = subprocess.run(
        [SENDMAIL, "-G", "-i"] + args,
        input=raw_bytes,
        env=env,
        check=False,
    )
    return result.returncode


def sender_domain(args):
    if "-f" in args:
        i = args.index("-f")
        if i + 1 < len(args):
            addr = args[i + 1].strip().strip("<>").lower()
            if "@" in addr:
                return addr.rsplit("@", 1)[-1]
    return ""


def read_footers():
    with open(DISCLAIMER_DIR + "/corporate-footer.html", encoding="utf-8") as fh:
        html = fh.read()
    with open(DISCLAIMER_DIR + "/corporate-footer.txt", encoding="utf-8") as fh:
        text = fh.read()
    return html, text


def is_automated(msg):
    prec = (msg.get("Precedence") or "").lower()
    if prec in ("bulk", "list", "junk"):
        return True
    auto = (msg.get("Auto-Submitted") or "").lower()
    if auto and auto != "no":
        return True
    if msg.get("List-Unsubscribe") or msg.get("List-Id"):
        return True
    return False


def append_footer(msg, html_footer, text_footer):
    """Append footers to visible body parts. Returns True if anything changed."""
    changed = False
    for part in msg.walk():
        if part.is_multipart():
            continue
        if part.get_content_disposition() == "attachment":
            continue
        ctype = part.get_content_type()
        try:
            if ctype == "text/html":
                body = part.get_content()
                low = body.lower()
                idx = low.rfind("</body>")
                if idx != -1:
                    body = body[:idx] + html_footer + body[idx:]
                else:
                    body = body + html_footer
                part.set_content(body, subtype="html")
                changed = True
            elif ctype == "text/plain":
                body = part.get_content()
                part.set_content(body + text_footer, subtype="plain")
                changed = True
        except (LookupError, ValueError):
            # Undecodable/unknown charset — leave this part untouched
            continue
    return changed


def main():
    args = sys.argv[1:]
    raw = sys.stdin.buffer.read()

    try:
        if sender_domain(args) not in SIGN_DOMAINS:
            return reinject(raw, args)

        msg = BytesParser(policy=policy.default).parsebytes(raw)

        if msg.get(FLAG_HEADER) or is_automated(msg):
            return reinject(raw, args)

        html_footer, text_footer = read_footers()
        if not append_footer(msg, html_footer, text_footer):
            return reinject(raw, args)

        del msg[FLAG_HEADER]
        msg[FLAG_HEADER] = FLAG_VALUE

        return reinject(msg.as_bytes(policy=policy.default), args)
    except Exception:
        # Never lose mail: fall back to the original message.
        try:
            return reinject(raw, args)
        except Exception:
            return EX_TEMPFAIL


if __name__ == "__main__":
    sys.exit(main())

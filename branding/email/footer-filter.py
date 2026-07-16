#!/usr/bin/python3
"""Postfix content filter that appends the SuperTech corporate footer.

Wired into master.cf as the `footerfilter` pipe service and attached to the
authenticated submission services (587/465/588 + haproxy variants). Those
services have their milter disabled, so this filter runs BEFORE any DKIM
signing: it appends the footer, then reinjects the message with `sendmail`.
The reinjected message is signed by rspamd on the way out (sign_local=true),
so DKIM covers the footered body with a single valid signature.

Owner name / title / phone are read live from the Mailcow mailbox record
(Full name + custom attributes `title` and `phone`). See docs/EMAIL_FOOTER.md.

Safety: on ANY error the ORIGINAL message is reinjected unchanged, so mail is
never lost or corrupted by this filter. Only if reinjection itself fails do we
return EX_TEMPFAIL so Postfix retries.
"""
import html
import json
import os
import ssl
import sys
import subprocess
import urllib.error
import urllib.parse
import urllib.request
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
FLAG_VALUE = "SuperTech"
SIGN_DOMAINS = ("supertechltd.co.tz",)
API_CONFIG_PATH = DISCLAIMER_DIR + "/footer-api.env"
DEFAULT_API_BASE = "https://nginx-mailcow"
HOSTED_LOGO_URL = "https://mail.supertechltd.co.tz/img/supertech-logo.png?v=20260716"

FALLBACK_EMAIL = "info@supertechltd.co.tz"
FALLBACK_PHONE = "0784 777 711"
FALLBACK_PHONE_2 = ""

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


def envelope_sender(args):
    """Return the lowercase envelope sender address from -f, or empty string."""
    if "-f" in args:
        i = args.index("-f")
        if i + 1 < len(args):
            return args[i + 1].strip().strip("<>").lower()
    return ""


def sender_domain(args):
    addr = envelope_sender(args)
    if "@" in addr:
        return addr.rsplit("@", 1)[-1]
    return ""


def read_footers():
    with open(DISCLAIMER_DIR + "/corporate-footer.html", encoding="utf-8") as fh:
        html_tmpl = fh.read()
    with open(DISCLAIMER_DIR + "/corporate-footer.txt", encoding="utf-8") as fh:
        text = fh.read()
    return html_tmpl, text


def load_api_config():
    """Load API_KEY / API_BASE from footer-api.env (server-local, not in git)."""
    cfg = {"API_KEY": "", "API_BASE": DEFAULT_API_BASE}
    try:
        with open(API_CONFIG_PATH, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, val = line.split("=", 1)
                cfg[key.strip()] = val.strip().strip('"').strip("'")
    except OSError:
        pass
    return cfg


def fetch_mailbox(username):
    """GET mailbox details from Mailcow API. Returns dict or None."""
    cfg = load_api_config()
    api_key = cfg.get("API_KEY") or ""
    if not api_key:
        return None
    base = (cfg.get("API_BASE") or DEFAULT_API_BASE).rstrip("/")
    url = base + "/api/v1/get/mailbox/" + urllib.parse.quote(username, safe="@")
    req = urllib.request.Request(
        url,
        headers={"X-API-Key": api_key, "Accept": "application/json"},
        method="GET",
    )
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=3) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, ValueError):
        return None
    if isinstance(data, list):
        if not data:
            return None
        data = data[0]
    if not isinstance(data, dict):
        return None
    # Mailcow sometimes returns an error object instead of a mailbox
    if data.get("type") == "error" or "username" not in data and "name" not in data:
        if "username" not in data:
            return None
    return data


def parse_custom_attributes(raw):
    if raw is None or raw == "":
        return {}
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        try:
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, dict) else {}
        except json.JSONDecodeError:
            return {}
    return {}


def contact_fields(sender):
    """Resolve contact placeholders for the sender mailbox."""
    mailbox = fetch_mailbox(sender) if sender else None
    if mailbox:
        attrs = parse_custom_attributes(mailbox.get("custom_attributes"))
        title = str(attrs.get("title") or "").strip()
        phone = str(attrs.get("phone") or "").strip()
        name = str(mailbox.get("name") or "").strip()
        if title or phone:
            return {
                "sender_email": sender,
                "owner_name": name,
                "owner_title": title,
                "owner_phone": phone or FALLBACK_PHONE,
                "owner_phone_2": "",
                "personalized": True,
            }
    return {
        "sender_email": FALLBACK_EMAIL,
        "owner_name": "",
        "owner_title": "",
        "owner_phone": FALLBACK_PHONE,
        "owner_phone_2": FALLBACK_PHONE_2,
        "personalized": False,
    }


def render_footers(html_tmpl, text_tmpl, fields):
    """Fill HTML/TXT placeholders from contact fields."""
    name = fields["owner_name"]
    title = fields["owner_title"]
    email = fields["sender_email"]
    phone = fields["owner_phone"]
    phone2 = fields["owner_phone_2"]

    if name:
        name_block = (
            '<div style="font-size:10px;font-weight:700;color:#FFFFFF;line-height:1.25;">'
            + html.escape(name)
            + "</div>"
        )
    else:
        name_block = ""

    if title:
        title_block = (
            '<div style="font-size:9px;color:#B8D4F0;margin:1px 0 2px;">'
            + html.escape(title)
            + "</div>"
        )
    else:
        title_block = ""

    if phone2:
        phone2_desktop = (
            '<div style="color:#D0E4F8;">' + html.escape(phone2) + "</div>"
        )
        phone2_mobile = (
            '<td style="color:#D0E4F8;font-size:10px;padding-top:4px;white-space:nowrap;">'
            + html.escape(phone2)
            + "</td>"
        )
    else:
        phone2_desktop = ""
        phone2_mobile = ""

    html_out = (
        html_tmpl.replace("{{owner_name_block}}", name_block)
        .replace("{{owner_title_block}}", title_block)
        .replace("{{logo_src}}", HOSTED_LOGO_URL)
        .replace("{{sender_email}}", html.escape(email))
        .replace("{{owner_phone}}", html.escape(phone))
        .replace("{{owner_phone_2_desktop}}", phone2_desktop)
        .replace("{{owner_phone_2_mobile}}", phone2_mobile)
    )

    # Plain-text contact line
    parts = []
    if name:
        parts.append(name)
    if title:
        parts.append(title)
    parts.append(email)
    parts.append(phone)
    if phone2:
        parts.append(phone2)
    text_line = "Contact: " + " | ".join(parts)
    text_out = text_tmpl.replace("{{owner_text_line}}", text_line)

    return html_out, text_out


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

        sender = envelope_sender(args)
        fields = contact_fields(sender)
        html_tmpl, text_tmpl = read_footers()
        html_footer, text_footer = render_footers(html_tmpl, text_tmpl, fields)

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

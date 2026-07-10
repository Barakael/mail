# TERA Corporate Email Footer

Universal footer appended to every outgoing email from `@ticketfasta.co.tz` and
`@teratech.co.tz`. It is applied at the mail-transfer level, so it is identical
for every sender and every mail client (SOGo, Outlook, phones).

Status: **live** on `mail.ticketfasta.co.tz`.

## Files

| File | Purpose |
|------|---------|
| [`branding/email/footer-filter.py`](../branding/email/footer-filter.py) | Postfix content filter that appends the footer (DKIM-safe) |
| [`branding/email/corporate-footer.html`](../branding/email/corporate-footer.html) | HTML snippet (table layout, inline CSS) |
| [`branding/email/corporate-footer.txt`](../branding/email/corporate-footer.txt) | Plain-text fallback for multipart messages |
| [`preview/email-footer.html`](../preview/email-footer.html) | Local browser preview |
| [`scripts/deploy-email-footer.sh`](../scripts/deploy-email-footer.sh) | Sync footer assets to the server |

## Design spec

- Single horizontal row, five columns (logo, company, locations, contact, badge + copyright)
- Target height ~108px (1.5 inch), max width 600px
- Colors: navy `#183b63`, accent red `#DC143C`, white text
- Logo loaded from `https://mail.ticketfasta.co.tz/img/tera-logo.png` (deployed by `scripts/deploy.sh`)

Content: company name, slogan (Speed, Quality and Integrity), HQ + condensed
offices, corporate contact, "Official Company Communication" badge, copyright.
Excludes all personal/employee elements (name, title, personal phone/email,
photo, QR, vCard, social, meeting buttons).

## How it works (DKIM-safe pipeline)

Mailcow signs DKIM via the rspamd milter *during* the SMTP submission stage,
which is before any `content_filter` runs. To keep DKIM valid, the footer is
added first and the message is then reinjected so it gets signed once, over the
final (footered) body:

```
Client → submission smtpd (587/465/588)   [milter DISABLED here]
       → footerfilter (footer-filter.py appends footer)
       → sendmail reinject → pickup/cleanup [rspamd milter signs DKIM]
       → delivery
```

Key facts that make this safe on this server:

- rspamd `dkim_signing` has `sign_local = true` and `use_domain = "envelope"`,
  so a message reinjected from localhost with the original envelope sender is
  signed with the correct domain key.
- The submission services have `-o smtpd_milters=` so DKIM is **not** applied on
  the first pass — avoiding a broken signature over the pre-footer body.
- `footer-filter.py` reinjects with `MAIL_CONFIG=/etc/postfix`. Mailcow runs
  Postfix from `/opt/postfix/conf`, which `postdrop` rejects as unauthorized;
  `/etc/postfix` shares the same `queue_directory` (`/var/spool/postfix`), so
  reinjection lands in the running instance's queue.
- The filter adds an `X-Corporate-Footer: TERA` header and skips messages that
  already have it (loop guard), plus bulk/list/auto-submitted mail.
- On any error the original message is reinjected unchanged, so mail is never
  lost or corrupted by the filter.

## Local preview

```bash
./scripts/preview.sh
```

Open **http://localhost:8765/preview/email-footer.html** (login preview is at
`/preview/login.html`). The preview swaps the hosted logo URL for the local file.

## Deploy footer changes

After editing the footer HTML/TXT or the filter:

```bash
./scripts/deploy-email-footer.sh
```

Filter/footer changes take effect on the next message — no reload needed
(the pipe spawns a fresh process per message). A `postfix reload` is only
required after changing `master.cf`.

## One-time server wiring (already done — for reference / rebuild)

If the server is rebuilt from scratch, re-apply the Postfix wiring.

### 1. Assets

```bash
./scripts/deploy-email-footer.sh
```

Lands in `/opt/mailcow-dockerized/data/conf/postfix/disclaimer/`
(= `/opt/postfix/conf/disclaimer/` in the container).

### 2. master.cf

Add the pipe service (end of `data/conf/postfix/master.cf`):

```
# TERA corporate footer content filter (DKIM-safe: runs before signing)
footerfilter unix - n n - - pipe
  flags=Rq user=nobody null_sender=
  argv=/opt/postfix/conf/disclaimer/footer-filter.py -f ${sender} -- ${recipient}
```

Add these two lines to each authenticated submission service
(`smtps`, `10465`, `submission`, `10587`, `588`):

```
  -o content_filter=footerfilter:dummy
  -o smtpd_milters=
```

### 3. Validate and reload

```bash
cd /opt/mailcow-dockerized
docker compose exec postfix-mailcow postfix check
docker compose exec postfix-mailcow postfix reload
```

A timestamped backup of the original is kept as
`data/conf/postfix/master.cf.bak-footer-*`.

### Durability note

- `master.cf`, the filter, and footer assets live under bind-mounted
  `data/conf/postfix/`, so they survive container restarts and recreation.
- The filter uses the built-in `nobody` user and the container's built-in
  `python3` — no packages to install, nothing to lose on a Mailcow update.
- A future Mailcow release could ship a changed `master.cf`; `update.sh` will
  flag the local modification for merge. Re-apply the two blocks above if needed.

## Test checklist

- [x] Footer appended to HTML and plain-text parts
- [x] `X-Corporate-Footer: TERA` present; loop guard prevents double-append
- [x] Attachments preserved intact
- [x] Message delivered (`status=sent ... delivered via footerfilter service`)
- [ ] External DKIM check `dkim=pass` (send to Gmail "Show original" or
      `check-auth@verifier.port25.com` and read the reply in the `info@` inbox)

### Verify a delivered message

```bash
cd /opt/mailcow-dockerized
docker compose exec dovecot-mailcow \
  doveadm fetch -u info@ticketfasta.co.tz text \
  mailbox INBOX HEADER SUBJECT <your-subject>
```

### Watch the pipeline live

```bash
docker compose logs -f postfix-mailcow | grep -iE "footerfilter|status="
```

## Rollback

Restore the backup and reload:

```bash
cd /opt/mailcow-dockerized/data/conf/postfix
cp master.cf.bak-footer-<stamp> master.cf
cd /opt/mailcow-dockerized
docker compose exec postfix-mailcow postfix reload
```

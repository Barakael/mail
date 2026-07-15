# TERA Corporate Email Footer

Footer appended to every outgoing email from `@ticketfasta.co.tz` and
`@teratech.co.tz`. Brand / HQ / badge columns are the same for everyone; the
**contact column** shows the sending mailbox’s owner (Full name, title, phone)
when those fields are set on the mailbox in Mailcow admin.

Status: **live** on `mail.ticketfasta.co.tz`.

## Files

| File | Purpose |
|------|---------|
| [`branding/email/footer-filter.py`](../branding/email/footer-filter.py) | Postfix content filter that appends the footer (DKIM-safe) and looks up mailbox owners |
| [`branding/email/corporate-footer.html`](../branding/email/corporate-footer.html) | HTML template (placeholders for contact column) |
| [`branding/email/corporate-footer.txt`](../branding/email/corporate-footer.txt) | Plain-text template |
| [`scripts/set-mailbox-owner.sh`](../scripts/set-mailbox-owner.sh) | Set Full name + `title` / `phone` custom attributes via API |
| [`preview/email-footer.html`](../preview/email-footer.html) | Local browser preview (sender selector) |
| [`scripts/deploy-email-footer.sh`](../scripts/deploy-email-footer.sh) | Sync footer assets + install `footer-api.env` on the server |

Server-only (never commit): `data/conf/postfix/disclaimer/footer-api.env` — API key used by the filter to look up mailboxes.

## Owner details (mailbox-backed — not hard-coded)

Source of truth is the **Mailcow mailbox**:

| Detail | Where in Mailcow |
|--------|------------------|
| Name | **Full name** on Add / Edit mailbox |
| Title | Custom attribute key `title` |
| Phone | Custom attribute key `phone` |

### Admin workflow (new mailbox)

1. **Admin** → Configuration → Mailboxes → **Add**: set the address and **Full name**.
2. Open that mailbox → **Custom attributes** → add:
   - `title` — e.g. `Head of Software Department`
   - `phone` — e.g. `+255629288966`
3. Save. The next message sent from that address uses these details in the footer.

If title and phone are both missing (or the lookup fails), the footer falls back to the generic company contact (`info@teratech.co.tz` + HQ phones).

### Helper script

```bash
./scripts/set-mailbox-owner.sh EMAIL "Full Name" "Title" "Phone"
```

### Seed existing mailboxes

```bash
./scripts/set-mailbox-owner.sh info@ticketfasta.co.tz \
  "Barakael Lucas" "Head of Software Department" "+255629288966"

./scripts/set-mailbox-owner.sh support@ticketfasta.co.tz \
  "Marcelina Nki" "Business Analyst" "0770497383"
```

## Design spec

- Single horizontal row up to 720px on desktop (≥481px), four columns: brand block, HQ, contact, badge + copyright
- On mobile (≤480px): sections stack vertically; copyright moves to a dedicated bottom row
- Contact column: owner name + title (when set), mailbox address, phone(s)
- Colors: navy `#183b63`, accent red `#DC143C`, white text
- Logo: embedded as an inline CID image in each HTML email; the hosted URL is
  used only if the local logo asset cannot be read

## How it works (DKIM-safe pipeline)

```
Client → submission smtpd (587/465/588)   [milter DISABLED here]
       → footerfilter (look up mailbox → fill template → append footer)
       → sendmail reinject → pickup/cleanup [rspamd milter signs DKIM]
       → delivery
```

Key facts:

- rspamd `dkim_signing` has `sign_local = true` and `use_domain = "envelope"`.
- Submission services have `-o smtpd_milters=` so DKIM is not applied on the first pass.
- `footer-filter.py` reinjects with `MAIL_CONFIG=/etc/postfix`.
- The filter reads `footer-api.env` and calls `GET /api/v1/get/mailbox/<sender>` for Full name + custom attributes.
- HTML messages include `tera-logo.png` as an inline related MIME part, so
  recipients do not need to enable remote images to see the logo.
- Loop guard: `X-Corporate-Footer: TERA`; skips bulk/list/auto-submitted mail.
- On any error the original message is reinjected unchanged.

## Local preview

```bash
./scripts/preview.sh
```

Open **http://localhost:8765/preview/email-footer.html**. Use the sender buttons to preview `info@`, `support@`, and the unmapped company fallback (simulated locally — not live Mailcow).

## Deploy footer changes

```bash
./scripts/deploy-email-footer.sh
```

Syncs HTML/TXT/filter and writes `footer-api.env` from `/root/mailcow-credentials.txt`. Takes effect on the next message (no Postfix reload). Reload only after changing `master.cf`.

## One-time server wiring (already done — for reference / rebuild)

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

### Durability note

- Assets live under bind-mounted `data/conf/postfix/`.
- Filter uses container `python3` only (stdlib `urllib` for mailbox lookup).
- `footer-api.env` must remain owned by `root:65534` with mode `640`, allowing
  the `nobody` footer-filter process to read it without exposing it globally.

## Test checklist

- [x] Footer appended to HTML and plain-text parts
- [x] `X-Corporate-Footer: TERA` present; loop guard prevents double-append
- [x] Attachments preserved intact
- [x] Message delivered (`status=sent ... delivered via footerfilter service`)
- [ ] Owner contact shows for mailboxes with `title` / `phone` custom attributes
- [ ] Unmapped senders get company fallback contact
- [ ] External DKIM check `dkim=pass`

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

```bash
cd /opt/mailcow-dockerized/data/conf/postfix
cp master.cf.bak-footer-<stamp> master.cf
cd /opt/mailcow-dockerized
docker compose exec postfix-mailcow postfix reload
```

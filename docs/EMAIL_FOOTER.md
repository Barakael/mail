# TERA Corporate Email Footer

Universal HTML footer appended to every outgoing email from `@ticketfasta.co.tz` and `@teratech.co.tz` mailboxes.

## Files

| File | Purpose |
|------|---------|
| [`branding/email/corporate-footer.html`](../branding/email/corporate-footer.html) | HTML snippet (table layout, inline CSS) |
| [`branding/email/corporate-footer.txt`](../branding/email/corporate-footer.txt) | Plain-text fallback for multipart messages |
| [`branding/email/postfix-disclaimer`](../branding/email/postfix-disclaimer) | Postfix pipe script for alterMIME |
| [`preview/email-footer.html`](../preview/email-footer.html) | Local browser preview |

## Design spec

- **Layout:** Single horizontal row, five columns (logo, company, locations, contact, badge + copyright)
- **Height:** ~108px (1.5 inch) at typical email zoom
- **Width:** 600px max
- **Colors:** Navy `#183b63`, accent red `#DC143C`, white text
- **Logo:** CID `tera-logo` in production HTML (embedded by alterMIME or inline attachment)

### Content included

- Tera Technologies and Engineering Limited
- Slogan: Speed, Quality and Integrity
- HQ: Mbezi Beach, Dar es Salaam, Tanzania
- Offices: Dar es Salaam (Mwenge) · Dodoma
- info@teratech.co.tz, +255 22 2701612, +255 713 899 309
- Official Company Communication badge
- © 2026 copyright

### Excluded (per corporate policy)

Employee name, job title, personal phone/email, photo, QR code, vCard, social links, meeting buttons.

## Local preview

```bash
./scripts/preview.sh
```

Open:

- **http://localhost:8765/preview/email-footer.html** — footer in a sample email context
- **http://localhost:8765/preview/login.html** — login page (unchanged)

The preview page loads `corporate-footer.html` and swaps `cid:tera-logo` for the local logo path. Place `branding/mailcow-ui/tera-logo.png` on disk for the logo to appear.

## Deploy footer files to server

From your Mac:

```bash
chmod +x scripts/deploy-email-footer.sh
./scripts/deploy-email-footer.sh
```

This uploads footer HTML/TXT, logo, and the Postfix filter script to the Mailcow host. It does **not** enable alterMIME automatically — see below.

## Mailcow / Postfix setup (one-time)

Mailcow has no built-in universal HTML footer ([mailcow#4267](https://github.com/mailcow/mailcow-dockerized/issues/4267)). Use **alterMIME** on the `postfix-mailcow` container.

### Pipeline order (critical)

Footer injection must happen **before DKIM signing** or signatures will fail.

```
Sender → Postfix → alterMIME (append footer) → Rspamd (DKIM sign) → Internet
```

### 1. Install alterMIME in postfix container

```bash
ssh root@161.97.182.204
cd /opt/mailcow-dockerized
docker compose exec postfix-mailcow bash -c 'apt-get update && apt-get install -y altermime'
```

For a durable setup, build a custom postfix image with `altermime` pre-installed instead of exec-install after each container recreate.

### 2. Deploy footer assets

```bash
./scripts/deploy-email-footer.sh
```

Files land in `/opt/postfix/conf/disclaimer/` inside the postfix container:

- `corporate-footer.html`
- `corporate-footer.txt`
- `tera-logo.png`
- `disclaimer` (executable filter script)

### 3. Configure Postfix content filter

Edit postfix `master.cf` inside the container (or via Mailcow override mount). Add a content filter for outbound SMTP:

```
smtp      inet  n       -       y       -       -       smtpd
  -o content_filter=dfilt:

dfilt     unix  -       n       n       -       -       pipe
  flags=Rq user=filter argv=/opt/postfix/conf/disclaimer/disclaimer -f ${sender} -- ${recipient}
```

Ensure local submission still works (`127.0.0.1:smtp` without the filter if needed).

Create a `filter` system user in the container if it does not exist:

```bash
docker compose exec postfix-mailcow useradd -r -s /bin/false filter 2>/dev/null || true
chmod 750 /opt/postfix/conf/disclaimer/disclaimer
chown filter:filter /opt/postfix/conf/disclaimer/disclaimer
```

Reload Postfix:

```bash
docker compose exec postfix-mailcow postfix reload
```

### 4. Logo CID (optional)

If the logo does not render, configure alterMIME to attach `tera-logo.png` as an inline CID, or change the `src` in `corporate-footer.html` to a stable HTTPS URL:

```
https://mail.ticketfasta.co.tz/img/tera-logo.png
```

Hosted URLs may be blocked by some clients; CID embedding is more reliable.

## Test checklist

- [ ] Send HTML email from `info@ticketfasta.co.tz` to an external address (Gmail/Outlook)
- [ ] Footer appears as a single navy bar below the message body
- [ ] Height is approximately 1.5 inch; no excessive wrapping on desktop clients
- [ ] Plain-text part shows the `corporate-footer.txt` content
- [ ] DKIM passes: `Authentication-Results: dkim=pass`
- [ ] DMARC passes for `ticketfasta.co.tz`
- [ ] Auto-replies / bounces do **not** get the footer (filter script skips them)
- [ ] Inbound mail is unaffected

### Quick DKIM check

```bash
# On server — watch postfix log while sending test mail
docker compose logs -f postfix-mailcow rspamd-mailcow
```

Use [mail-tester.com](https://www.mail-tester.com) or Gmail “Show original” to verify headers.

## Updating the footer

1. Edit `branding/email/corporate-footer.html` and/or `.txt`
2. Preview locally at `http://localhost:8765/preview/email-footer.html`
3. Run `./scripts/deploy-email-footer.sh`
4. Send a test email — no Postfix reload needed unless the filter script changed

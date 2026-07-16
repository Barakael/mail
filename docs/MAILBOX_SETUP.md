# Mailbox setup — info@supertechltd.co.tz

## Webmail

1. Open https://mail.supertechltd.co.tz/
2. Log in with:
   - **Email:** `info@supertechltd.co.tz`
   - **Password:** (set in Mailcow admin — see [OPERATIONS.md](OPERATIONS.md))
3. Or go directly to https://mail.supertechltd.co.tz/SOGo after login

## Mail client settings

| Setting | Value |
|---------|-------|
| **Incoming (IMAP)** | |
| Server | `mail.supertechltd.co.tz` |
| Port | `993` |
| Security | SSL/TLS |
| **Outgoing (SMTP)** | |
| Server | `mail.supertechltd.co.tz` |
| Port | `587` (STARTTLS) or `465` (SSL) |
| Security | STARTTLS or SSL |
| Authentication | Required (same as IMAP) |
| **Username** | `info@supertechltd.co.tz` (full address) |
| **Password** | mailbox password |

## DNS required for sending (supertechltd.co.tz)

Publish these at your DNS provider. Run `./scripts/verify-mail.sh` to check.

| Type | Name | Value |
|------|------|-------|
| A | `mail` | `161.97.182.204` |
| MX | `@` | `10 mail.supertechltd.co.tz` |
| TXT | `@` | `v=spf1 mx a:mail.supertechltd.co.tz -all` |
| TXT | `dkim._domainkey` | See Mailcow: Configuration → Configuration & Details → ARC/DKIM keys |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:dmarc@supertechltd.co.tz` |

**Reverse DNS (Contabo):** PTR for `161.97.182.204` must be `mail.supertechltd.co.tz` (not the default Contabo hostname).

## Deliverability test

1. Log into SOGo as `info@supertechltd.co.tz`
2. Send a message to an external address (e.g. Gmail)
3. Optional: use https://www.mail-tester.com — aim for 9+/10

## Troubleshooting

| Problem | Check |
|---------|-------|
| Login fails | Full email as username; reset password in Mailcow admin |
| "Relay access denied" | Use SMTP port 587 with authentication |
| Mail goes to spam | SPF, DKIM, DMARC, and PTR must all be correct |
| Account locked | Fail2ban — unban IP in Mailcow admin |

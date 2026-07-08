# Mailbox setup — info@ticketfasta.co.tz

## Webmail

1. Open https://mail.ticketfasta.co.tz/
2. Log in with:
   - **Email:** `info@ticketfasta.co.tz`
   - **Password:** (set in Mailcow admin — see [OPERATIONS.md](OPERATIONS.md))
3. Or go directly to https://mail.ticketfasta.co.tz/SOGo after login

## Mail client settings

| Setting | Value |
|---------|-------|
| **Incoming (IMAP)** | |
| Server | `mail.ticketfasta.co.tz` |
| Port | `993` |
| Security | SSL/TLS |
| **Outgoing (SMTP)** | |
| Server | `mail.ticketfasta.co.tz` |
| Port | `587` (STARTTLS) or `465` (SSL) |
| Security | STARTTLS or SSL |
| Authentication | Required (same as IMAP) |
| **Username** | `info@ticketfasta.co.tz` (full address) |
| **Password** | mailbox password |

## DNS required for sending (ticketfasta.co.tz)

Publish these at your DNS provider. Run `./scripts/verify-mail.sh` to check.

| Type | Name | Value |
|------|------|-------|
| A | `mail` | `161.97.182.204` |
| MX | `@` | `10 mail.ticketfasta.co.tz` |
| TXT | `@` | `v=spf1 mx a:mail.ticketfasta.co.tz -all` |
| TXT | `dkim._domainkey` | See Mailcow: Configuration → Configuration & Details → ARC/DKIM keys |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:dmarc@ticketfasta.co.tz` |

**Reverse DNS (Contabo):** PTR for `161.97.182.204` must be `mail.ticketfasta.co.tz` (not the default Contabo hostname).

## Deliverability test

1. Log into SOGo as `info@ticketfasta.co.tz`
2. Send a message to an external address (e.g. Gmail)
3. Optional: use https://www.mail-tester.com — aim for 9+/10

## Troubleshooting

| Problem | Check |
|---------|-------|
| Login fails | Full email as username; reset password in Mailcow admin |
| "Relay access denied" | Use SMTP port 587 with authentication |
| Mail goes to spam | SPF, DKIM, DMARC, and PTR must all be correct |
| Account locked | Fail2ban — unban IP in Mailcow admin |

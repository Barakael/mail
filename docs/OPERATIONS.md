# SuperTech Mail — Operations

## Server

| Item | Value |
|------|-------|
| Host | `161.97.182.204` |
| SSH | `ssh root@161.97.182.204` |
| Mailcow path | `/opt/mailcow-dockerized` |
| Mail hostname | `mail.supertechltd.co.tz` |
| Domain | `supertechltd.co.tz` |

## URLs

| Purpose | URL |
|---------|-----|
| User login | https://mail.supertechltd.co.tz/ |
| Webmail (SOGo) | https://mail.supertechltd.co.tz/SOGo |
| Admin | https://mail.supertechltd.co.tz/admin |
| Domain admin | https://mail.supertechltd.co.tz/domainadmin |

## Primary mailbox

- **Address:** `info@supertechltd.co.tz`
- **Username:** full email (`info@supertechltd.co.tz`), not just `info`

## Mailbox owner details (email footer)

The corporate footer contact column uses the mailbox **Full name** plus custom attributes `title` and `phone`. Set them in Mailcow admin (Edit mailbox → Custom attributes), or:

```bash
./scripts/set-mailbox-owner.sh EMAIL "Full Name" "Title" "Phone"
```

Seed the current owners:

```bash
./scripts/set-mailbox-owner.sh info@supertechltd.co.tz \
  "Barakael Lucas" "Head of Software Department" "+255629288966"

./scripts/set-mailbox-owner.sh support@supertechltd.co.tz \
  "Marcelina Nki" "Business Analyst" "0770497383"
```

See [EMAIL_FOOTER.md](EMAIL_FOOTER.md) for the full workflow.

## Deploy branding (from your Mac)

```bash
cd ~/ticketfasta-mail-platform
git pull origin master
./scripts/deploy.sh
```

Uploads logos, CSS, Twig templates, and UI text from `branding/` and `custom/` to the live server.

## Verify DNS and HTTPS (from your Mac)

```bash
./scripts/verify-mail.sh
```

## Credentials (server only — never commit)

Stored on the server at `/root/mailcow-credentials.txt`:

- `API_KEY` — Mailcow API key (used by deploy script)
- Mailbox passwords — set via Mailcow admin or API

## Password reset

### Mailcow admin account

```bash
ssh root@161.97.182.204
cd /opt/mailcow-dockerized
./helper-scripts/mailcow-reset-admin.sh
```

### Mailbox (e.g. info@)

**Mailcow UI:** Configuration → Mail setup → Mailboxes → edit mailbox → set new password

Or via API (from server):

```bash
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2)
curl -sk -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  -X POST https://127.0.0.1/api/v1/edit/mailbox \
  -d '{"items":["info@supertechltd.co.tz"],"attr":{"password":"NEW_PASSWORD","password2":"NEW_PASSWORD"}}'
```

## Container health

```bash
cd /opt/mailcow-dockerized
docker compose ps
docker compose logs --tail=50 postfix-mailcow dovecot-mailcow sogo-mailcow
```

## Fail2ban

If login fails after many attempts, check **System → Fail2ban** in Mailcow admin or:

```bash
docker compose exec fail2ban-mailcow fail2ban-client status
```

## Git repository

- Remote: `git@github.com:Barakael/mail.git`
- This repo holds branding and templates only — not Mailcow itself.

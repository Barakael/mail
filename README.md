# Ticketfasta Mail

Customize the Mailcow login page and webmail theme, deploy to **mail.ticketfasta.co.tz**.

**Git:** `git@github.com:Barakael/mail.git`

## Quick start

### Preview locally (no Docker)

```bash
cd ~/ticketfasta-mail-platform
chmod +x scripts/*.sh
./scripts/preview.sh
```

Open **http://localhost:8765/preview/login.html**

### Deploy branding to live server

```bash
./scripts/deploy.sh
```

Then hard-refresh https://mail.ticketfasta.co.tz (Cmd+Shift+R).

### Verify DNS and HTTPS

```bash
./scripts/verify-mail.sh
```

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | Server access, deploy, password reset, container health |
| [docs/MAILBOX_SETUP.md](docs/MAILBOX_SETUP.md) | `info@ticketfasta.co.tz` client settings and troubleshooting |
| [docs/DNS_RECORDS.md](docs/DNS_RECORDS.md) | SPF, DKIM, DMARC, PTR records to publish |
| [docs/EMAIL_FOOTER.md](docs/EMAIL_FOOTER.md) | TERA corporate email footer (mailbox-backed owner contact) |

## Folder structure

```
ticketfasta-mail-platform/
├── branding/           # Logos, CSS, UI text — deployed to server
├── custom/templates/   # Twig overrides (login page, Tera branding)
├── preview/            # Static local preview
├── scripts/
│   ├── deploy.sh       # Push branding to 161.97.182.204
│   ├── preview.sh      # Local HTTP preview server
│   └── verify-mail.sh  # DNS/HTTPS checks
├── docs/               # Operations and DNS guides
└── _upstream/          # Mailcow reference (not in git)
```

## What to edit

| Goal | File |
|------|------|
| Login colors & buttons | `branding/mailcow-ui/custom.css` |
| Company name & footer | `branding/mailcow-ui/branding.env` |
| Logo | `branding/sogo/custom-fulllogo.svg` |
| Webmail theme | `branding/sogo/custom-theme.js` |
| Login page HTML | `custom/templates/user_index.twig` |
| Corporate email footer | `branding/email/corporate-footer.html` |

## Mailbox login

- **URL:** https://mail.ticketfasta.co.tz/
- **Username:** `info@ticketfasta.co.tz` (full email)
- **Password:** set on server — see [docs/OPERATIONS.md](docs/OPERATIONS.md)

## What this repo does *not* do

- Create mailboxes (use Mailcow admin at `/admin`)
- Edit DNS (use your registrar — see [docs/DNS_RECORDS.md](docs/DNS_RECORDS.md))
- Store passwords or API keys (server only: `/root/mailcow-credentials.txt`)

## Update upstream Mailcow reference

```bash
cd _upstream && git pull
```

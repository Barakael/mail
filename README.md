# Ticketfasta Mail — Local UI Customization

Customize the mail login page and webmail theme **on your Mac without Docker**.

## Folder structure

```
ticketfasta-mail-platform/
├── _upstream/              # Mailcow source (templates, CSS) — read-only reference
│   └── data/web/templates/ # Real Twig pages (user_index.twig = login)
├── branding/               # YOUR edits — deploy these to the server
│   ├── mailcow-ui/
│   │   ├── custom.css      # Colors, buttons, fonts
│   │   └── branding.env    # Title, footer text
│   └── sogo/
│       ├── custom-fulllogo.svg
│       ├── custom-shortlogo.svg
│       └── custom-theme.js # Webmail colors
├── custom/                 # Optional advanced overrides
│   ├── templates/          # Copy Twig files here to override on server
│   └── css/
├── preview/
│   └── login.html          # Static local preview of login page
└── scripts/
    ├── preview.sh          # Run local preview server
    └── deploy.sh           # Push to live server
```

## Quick start

### 1. Preview locally (no Docker)

```bash
cd ~/ticketfasta-mail-platform
chmod +x scripts/*.sh
./scripts/preview.sh
```

Open **http://localhost:8765/preview/login.html**

Edit `branding/mailcow-ui/custom.css` or SVG logos → refresh browser.

### 2. Deploy to live server

```bash
./scripts/deploy.sh
```

Then visit https://mail.ticketfasta.co.tz (Cmd+Shift+R to hard refresh).

## What to edit

| Goal | File |
|------|------|
| Login colors & buttons | `branding/mailcow-ui/custom.css` |
| Company name & footer | `branding/mailcow-ui/branding.env` |
| Logo | `branding/sogo/custom-fulllogo.svg` |
| Webmail theme | `branding/sogo/custom-theme.js` |
| Login page HTML structure | Copy `_upstream/data/web/templates/user_index.twig` → `custom/templates/` |

## Why not full Mailcow locally?

The full mail system (Postfix, Dovecot, DB) needs Docker on the server. For **design work**, you only need:

- **Preview** = static HTML + your CSS/logo (this repo)
- **Reference** = real Mailcow Twig/CSS in `_upstream/`
- **Deploy** = push branding to `161.97.182.204`

## Update upstream reference

```bash
cd _upstream && git pull
```

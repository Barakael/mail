# DNS records for supertechltd.co.tz mail

Publish at your DNS registrar. Run `./scripts/verify-mail.sh` to check.

## Required records

### A — mail host

```
mail.supertechltd.co.tz  →  161.97.182.204
```

### MX — inbound mail

```
supertechltd.co.tz  MX  10  mail.supertechltd.co.tz
```

### SPF — sender policy

```
supertechltd.co.tz  TXT  "v=spf1 mx a:mail.supertechltd.co.tz -all"
```

### DKIM — domain signing

**Selector:** `dkim`  
**Name:** `dkim._domainkey.supertechltd.co.tz`  
**Type:** TXT

Get the current value from the server (after the domain is added in Mailcow):

```bash
ssh root@161.97.182.204
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2)
curl -sk -H "X-API-Key: $API_KEY" https://127.0.0.1/api/v1/get/dkim/supertechltd.co.tz | python3 -m json.tool
```

Use the `dkim_txt` field as the TXT record value (may need to split into 255-char chunks if your DNS UI requires it).

### DMARC

```
_dmarc.supertechltd.co.tz  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@supertechltd.co.tz"
```

### Reverse DNS (PTR) — Contabo control panel

```
161.97.182.204  →  mail.supertechltd.co.tz
```

Fix in Contabo → Reverse DNS Management if PTR still shows a Contabo default hostname.

## Optional (autodiscover)

| Type | Name | Value |
|------|------|-------|
| CNAME | `autodiscover` | `mail.supertechltd.co.tz` |
| CNAME | `autoconfig` | `mail.supertechltd.co.tz` |

## Verify

```bash
./scripts/verify-mail.sh
```

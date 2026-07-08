# DNS records for ticketfasta.co.tz mail

Last verified from server API. Publish at your DNS registrar if missing.

## Required records

### A — mail host

```
mail.ticketfasta.co.tz  →  161.97.182.204
```

### MX — inbound mail

```
ticketfasta.co.tz  MX  10  mail.ticketfasta.co.tz
```

### SPF — sender policy

```
ticketfasta.co.tz  TXT  "v=spf1 mx a:mail.ticketfasta.co.tz -all"
```

### DKIM — domain signing

**Selector:** `dkim`  
**Name:** `dkim._domainkey.ticketfasta.co.tz`  
**Type:** TXT

Get the current value from the server:

```bash
ssh root@161.97.182.204
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2)
curl -sk -H "X-API-Key: $API_KEY" https://127.0.0.1/api/v1/get/dkim/ticketfasta.co.tz | python3 -m json.tool
```

Use the `dkim_txt` field as the TXT record value (may need to split into 255-char chunks if your DNS UI requires it).

**Current DKIM value (ticketfasta.co.tz, selector `dkim`):**

```
v=DKIM1;k=rsa;t=s;s=email;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuCY/LvkcPI9fjZa4Zs+jiFJGlHwSyKuRO89r3wOKUXRx1x8jij0mQ3OLWwEgcLdmQjZgv7mnU6pAjhXLkJNa6XyI+Bok2qvPH67+VtycJBaG2DzQzxgSuPw6d2ZhpK3xTABe7+dwo4yKCBjA0Az4VgsTKDv9IuuadvHDtY84XhvTCqN6UYgZV6QMRHu9mAAYqijDFiUjkQ8Vi3gMyYvGSqtU3800vpTmGYlcjhil578XTOuc/dwAQZBQzF+3Fi4GvyMkTnC0eQJtwrwGNyMiTTCu+S4bXCKquqMuzq2Cftznem5Q3Rz6OJhdAkmpzxiKrHbioikZmE7lJq1FMLsuGQIDAQAB
```

### DMARC

```
_dmarc.ticketfasta.co.tz  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@ticketfasta.co.tz"
```

### Reverse DNS (PTR) — Contabo control panel

```
161.97.182.204  →  mail.ticketfasta.co.tz
```

**Current issue:** PTR may still show `vmi3408292.contaboserver.net`. Fix in Contabo → Reverse DNS Management.

## Optional (autodiscover)

| Type | Name | Value |
|------|------|-------|
| CNAME | `autodiscover` | `mail.ticketfasta.co.tz` |
| CNAME | `autoconfig` | `mail.ticketfasta.co.tz` |

## Verify

```bash
./scripts/verify-mail.sh
```

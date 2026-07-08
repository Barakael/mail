#!/usr/bin/env bash
# Read-only DNS and HTTPS checks for Ticketfasta mail
set -euo pipefail

MAIL_HOST="mail.ticketfasta.co.tz"
DOMAIN="ticketfasta.co.tz"
IP="161.97.182.204"

echo "==> A record: $MAIL_HOST"
dig +short "$MAIL_HOST" A || true

echo ""
echo "==> MX record: $DOMAIN"
dig +short "$DOMAIN" MX || true

echo ""
echo "==> SPF (TXT on $DOMAIN)"
dig +short "$DOMAIN" TXT | grep -i spf || echo "(missing — add v=spf1 mx a:$MAIL_HOST -all)"

echo ""
echo "==> DKIM (dkim._domainkey.$DOMAIN)"
dig +short "dkim._domainkey.$DOMAIN" TXT || echo "(missing — publish from Mailcow DKIM keys)"

echo ""
echo "==> DMARC (_dmarc.$DOMAIN)"
dig +short "_dmarc.$DOMAIN" TXT || echo "(missing — add DMARC record)"

echo ""
echo "==> PTR for $IP"
PTR=$(dig +short -x "$IP" || true)
echo "$PTR"
if [[ "$PTR" == *"$MAIL_HOST"* ]]; then
  echo "OK: PTR matches mail hostname"
else
  echo "WARN: PTR should be $MAIL_HOST (fix in Contabo Reverse DNS)"
fi

echo ""
echo "==> HTTPS $MAIL_HOST"
curl -sI "https://$MAIL_HOST" | head -5 || echo "(HTTPS check failed)"

echo ""
echo "Done."

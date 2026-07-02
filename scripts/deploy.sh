#!/usr/bin/env bash
# Deploy branding from local repo to live mail server
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="root@161.97.182.204"
MAILCOW="/opt/mailcow-dockerized"
DIR="$ROOT/branding"

[[ -f "${DIR}/mailcow-ui/branding.env" ]] && source "${DIR}/mailcow-ui/branding.env"
TITLE_NAME="${TITLE_NAME:-Ticketfasta Mail}"
MAIN_NAME="${MAIN_NAME:-Ticketfasta}"
APPS_NAME="${APPS_NAME:-Mail Apps}"
UI_FOOTER="${UI_FOOTER:-© 2026 Ticketfasta}"

echo "==> Uploading..."
scp "${DIR}/sogo/custom-fulllogo.svg" "${SERVER}:${MAILCOW}/data/conf/sogo/"
scp "${DIR}/sogo/custom-shortlogo.svg" "${SERVER}:${MAILCOW}/data/conf/sogo/"
scp "${DIR}/sogo/custom-theme.js" "${SERVER}:${MAILCOW}/data/conf/sogo/"
scp "${DIR}/mailcow-ui/custom.css" "${SERVER}:/tmp/mailcow-custom.css"
[[ -f "${DIR}/mailcow-ui/favicon.png" ]] && scp "${DIR}/mailcow-ui/favicon.png" "${SERVER}:${MAILCOW}/data/web/favicon.png"
[[ -f "${DIR}/mailcow-ui/tera-logo.png" ]] && scp "${DIR}/mailcow-ui/tera-logo.png" "${SERVER}:${MAILCOW}/data/web/img/tera-logo.png"

# Optional Twig/CSS overrides
if [[ -d "$ROOT/custom/templates" ]]; then
  scp -r "$ROOT/custom/templates/"* "${SERVER}:${MAILCOW}/data/web/templates/" 2>/dev/null || true
fi
if [[ -f "$ROOT/custom/css/override.css" ]]; then
  scp "$ROOT/custom/css/override.css" "${SERVER}:${MAILCOW}/data/web/css/site/custom-override.css"
fi

ssh "${SERVER}" "TITLE_NAME=$(printf %q "$TITLE_NAME") MAIN_NAME=$(printf %q "$MAIN_NAME") APPS_NAME=$(printf %q "$APPS_NAME") UI_FOOTER=$(printf %q "$UI_FOOTER") bash -s" << 'REMOTE'
set -euo pipefail
cd /opt/mailcow-dockerized
REDIS_PASS=$(grep ^REDISPASS= mailcow.conf | cut -d= -f2)
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2)
docker compose exec -T redis-mailcow redis-cli -a "$REDIS_PASS" SET CUSTOM_CSS "$(cat /tmp/mailcow-custom.css)" >/dev/null
LOGO_B64=$(base64 -w0 data/conf/sogo/custom-fulllogo.svg)
docker compose exec -T redis-mailcow redis-cli -a "$REDIS_PASS" SET MAIN_LOGO "data:image/svg+xml;base64,${LOGO_B64}" >/dev/null
docker compose exec -T redis-mailcow redis-cli -a "$REDIS_PASS" SET MAIN_LOGO_DARK "data:image/svg+xml;base64,${LOGO_B64}" >/dev/null
PAYLOAD=$(python3 -c "import json,os; print(json.dumps({'attr':{'title_name':os.environ['TITLE_NAME'],'main_name':os.environ['MAIN_NAME'],'apps_name':os.environ['APPS_NAME'],'ui_footer':os.environ['UI_FOOTER']}}))")
curl -sk -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -X POST https://127.0.0.1/api/v1/edit/ui_texts -d "$PAYLOAD" >/dev/null
docker compose restart memcached-mailcow sogo-mailcow
REMOTE
echo "==> Deployed to https://mail.ticketfasta.co.tz"

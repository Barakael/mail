#!/usr/bin/env bash
# Deploy branding from local repo to live mail server
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="root@161.97.182.204"
MAILCOW="/opt/mailcow-dockerized"
DIR="$ROOT/branding"

[[ -f "${DIR}/mailcow-ui/branding.env" ]] && source "${DIR}/mailcow-ui/branding.env"
TITLE_NAME="${TITLE_NAME:-SuperTech Mail}"
MAIN_NAME="${MAIN_NAME:-SuperTech}"
APPS_NAME="${APPS_NAME:-Mail Apps}"
UI_FOOTER="${UI_FOOTER:-© 2026 SuperTech Limited}"

echo "==> Uploading..."
scp "${DIR}/sogo/custom-fulllogo.svg" "${SERVER}:${MAILCOW}/data/conf/sogo/"
scp "${DIR}/sogo/custom-shortlogo.svg" "${SERVER}:${MAILCOW}/data/conf/sogo/"
scp "${DIR}/sogo/custom-theme.js" "${SERVER}:${MAILCOW}/data/conf/sogo/"
# Mailcow reads custom UI CSS from css/build/ — NOT from Redis CUSTOM_CSS
scp "${DIR}/mailcow-ui/custom.css" "${SERVER}:/tmp/mailcow-custom.css"
if [[ -f "$ROOT/preview/preview.css" ]]; then
  scp "$ROOT/preview/preview.css" "${SERVER}:/tmp/mailcow-preview.css"
fi
[[ -f "${DIR}/mailcow-ui/favicon.png" ]] && scp "${DIR}/mailcow-ui/favicon.png" "${SERVER}:${MAILCOW}/data/web/favicon.png"
[[ -f "${DIR}/mailcow-ui/supertech-logo.png" ]] && scp "${DIR}/mailcow-ui/supertech-logo.png" "${SERVER}:${MAILCOW}/data/web/img/supertech-logo.png"
# Smaller logo speeds first paint on slow links
if command -v sips >/dev/null && [[ -f "${DIR}/mailcow-ui/supertech-logo.png" ]]; then
  sips -Z 120 "${DIR}/mailcow-ui/supertech-logo.png" --out /tmp/supertech-logo-opt.png >/dev/null 2>&1 \
    && scp /tmp/supertech-logo-opt.png "${SERVER}:${MAILCOW}/data/web/img/supertech-logo.png" || true
fi

# Optional Twig/CSS overrides
if [[ -d "$ROOT/custom/templates" ]]; then
  scp -r "$ROOT/custom/templates/"* "${SERVER}:${MAILCOW}/data/web/templates/"
fi
if [[ -f "$ROOT/custom/css/override.css" ]]; then
  scp "$ROOT/custom/css/override.css" "${SERVER}:${MAILCOW}/data/web/css/site/custom-override.css"
fi

ssh "${SERVER}" "TITLE_NAME=$(printf %q "$TITLE_NAME") MAIN_NAME=$(printf %q "$MAIN_NAME") APPS_NAME=$(printf %q "$APPS_NAME") UI_FOOTER=$(printf %q "$UI_FOOTER") bash -s" << 'REMOTE'
set -euo pipefail
cd /opt/mailcow-dockerized
REDIS_PASS=$(grep ^REDISPASS= mailcow.conf | cut -d= -f2)
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2)
# Merge login + preview styles into Mailcow's official custom CSS slot
{
  cat /tmp/mailcow-custom.css
  [[ -f /tmp/mailcow-preview.css ]] && echo && cat /tmp/mailcow-preview.css
} > data/web/css/build/0081-custom-mailcow.css
# Bust minified CSS cache so the new hash is picked up immediately
rm -f /tmp/*.css data/web/cache/*.css data/web/cache/twig/* 2>/dev/null || true
LOGO_B64=$(base64 -w0 data/conf/sogo/custom-fulllogo.svg)
docker compose exec -T redis-mailcow redis-cli -a "$REDIS_PASS" SET MAIN_LOGO "data:image/svg+xml;base64,${LOGO_B64}" >/dev/null
docker compose exec -T redis-mailcow redis-cli -a "$REDIS_PASS" SET MAIN_LOGO_DARK "data:image/svg+xml;base64,${LOGO_B64}" >/dev/null
PAYLOAD=$(python3 -c "import json,os; print(json.dumps({'attr':{'title_name':os.environ['TITLE_NAME'],'main_name':os.environ['MAIN_NAME'],'apps_name':os.environ['APPS_NAME'],'ui_footer':os.environ['UI_FOOTER']}}))")
curl -sk -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -X POST https://127.0.0.1/api/v1/edit/ui_texts -d "$PAYLOAD" >/dev/null
docker compose restart memcached-mailcow php-fpm-mailcow nginx-mailcow sogo-mailcow
REMOTE
echo "==> Deployed to https://mail.supertechltd.co.tz"

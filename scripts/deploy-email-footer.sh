#!/usr/bin/env bash
# Deploy corporate email footer assets to Mailcow postfix container
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="root@161.97.182.204"
MAILCOW="/opt/mailcow-dockerized"
EMAIL_DIR="$ROOT/branding/email"
REMOTE_DIR="/opt/mailcow-dockerized/data/conf/postfix/disclaimer"

echo "==> Uploading email footer assets..."
ssh "${SERVER}" "mkdir -p ${REMOTE_DIR}"
scp "${EMAIL_DIR}/corporate-footer.html" "${SERVER}:${REMOTE_DIR}/"
scp "${EMAIL_DIR}/corporate-footer.txt" "${SERVER}:${REMOTE_DIR}/"
scp "${EMAIL_DIR}/postfix-disclaimer" "${SERVER}:${REMOTE_DIR}/disclaimer"

if [[ -f "$ROOT/branding/mailcow-ui/tera-logo.png" ]]; then
  scp "$ROOT/branding/mailcow-ui/tera-logo.png" "${SERVER}:${REMOTE_DIR}/tera-logo.png"
else
  echo "==> Warning: branding/mailcow-ui/tera-logo.png not found — copying from live web root if present"
  ssh "${SERVER}" "cp ${MAILCOW}/data/web/img/tera-logo.png ${REMOTE_DIR}/tera-logo.png 2>/dev/null || true"
fi

echo "==> Installing into postfix-mailcow container..."
ssh "${SERVER}" bash -s << 'REMOTE'
set -euo pipefail
cd /opt/mailcow-dockerized
CONTAINER="postfix-mailcow"
DISCLAIMER_DIR="/opt/postfix/conf/disclaimer"
HOST_DIR="data/conf/postfix/disclaimer"

docker compose exec -T "${CONTAINER}" mkdir -p "${DISCLAIMER_DIR}"
for f in corporate-footer.html corporate-footer.txt tera-logo.png disclaimer; do
  if [[ -f "${HOST_DIR}/${f}" ]]; then
    docker compose cp "${HOST_DIR}/${f}" "${CONTAINER}:${DISCLAIMER_DIR}/${f}"
  fi
done

docker compose exec -T "${CONTAINER}" chmod 750 "${DISCLAIMER_DIR}/disclaimer" 2>/dev/null || true
docker compose exec -T "${CONTAINER}" useradd -r -s /bin/false filter 2>/dev/null || true
docker compose exec -T "${CONTAINER}" chown -R filter:filter "${DISCLAIMER_DIR}" 2>/dev/null || true

echo "Footer files installed in postfix container at ${DISCLAIMER_DIR}/"
echo ""
echo "Next steps (one-time): enable alterMIME — see docs/EMAIL_FOOTER.md"
REMOTE

echo "==> Done. See docs/EMAIL_FOOTER.md for alterMIME setup and testing."

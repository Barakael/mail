#!/usr/bin/env bash
# Deploy the TERA corporate email footer assets to the Mailcow server.
#
# The postfix container bind-mounts data/conf/postfix -> /opt/postfix/conf, so
# copying into data/conf/postfix/disclaimer/ is immediately visible in the
# container. The content-filter script (footer-filter.py) is picked up on the
# next message with no reload; a reload is only needed after master.cf changes.
#
# One-time master.cf wiring (footerfilter pipe + content_filter on submission
# services) is NOT done here — see docs/EMAIL_FOOTER.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="root@161.97.182.204"
MAILCOW="/opt/mailcow-dockerized"
EMAIL_DIR="$ROOT/branding/email"
REMOTE_DIR="${MAILCOW}/data/conf/postfix/disclaimer"

echo "==> Uploading email footer assets to ${REMOTE_DIR}"
ssh "${SERVER}" "mkdir -p ${REMOTE_DIR}"
scp "${EMAIL_DIR}/footer-filter.py"      "${SERVER}:${REMOTE_DIR}/footer-filter.py"
scp "${EMAIL_DIR}/corporate-footer.html" "${SERVER}:${REMOTE_DIR}/corporate-footer.html"
scp "${EMAIL_DIR}/corporate-footer.txt"  "${SERVER}:${REMOTE_DIR}/corporate-footer.txt"

# Logo is served publicly from the web root; keep a copy alongside the filter too.
if [[ -f "$ROOT/branding/mailcow-ui/tera-logo.png" ]]; then
  scp "$ROOT/branding/mailcow-ui/tera-logo.png" "${SERVER}:${REMOTE_DIR}/tera-logo.png"
fi

echo "==> Setting permissions"
ssh "${SERVER}" "chmod 755 ${REMOTE_DIR}/footer-filter.py && chmod 644 ${REMOTE_DIR}/corporate-footer.* ${REMOTE_DIR}/tera-logo.png 2>/dev/null || true"

echo "==> Done."
echo "    Filter changes are live immediately (pipe spawns a fresh process per message)."
echo "    If this is the first install, wire master.cf once — see docs/EMAIL_FOOTER.md."

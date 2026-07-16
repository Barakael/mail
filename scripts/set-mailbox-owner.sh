#!/usr/bin/env bash
# Set mailbox Full name + custom attributes title/phone for the SuperTech email footer.
#
# Usage (from your Mac — runs on the live mail server via SSH):
#   ./scripts/set-mailbox-owner.sh EMAIL "Full Name" "Title" "Phone"
#
# Example:
#   ./scripts/set-mailbox-owner.sh info@supertechltd.co.tz \
#     "Barakael Lucas" "Head of Software Department" "+255629288966"
#
# Requires /root/mailcow-credentials.txt on the server (API_KEY=...).
set -euo pipefail

SERVER="root@161.97.182.204"

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 EMAIL \"Full Name\" \"Title\" \"Phone\"" >&2
  exit 1
fi

EMAIL="$1"
NAME="$2"
TITLE="$3"
PHONE="$4"

ssh "${SERVER}" \
  "EMAIL=$(printf %q "$EMAIL") NAME=$(printf %q "$NAME") TITLE=$(printf %q "$TITLE") PHONE=$(printf %q "$PHONE") bash -s" << 'REMOTE'
set -euo pipefail
API_KEY=$(grep ^API_KEY= /root/mailcow-credentials.txt | cut -d= -f2-)
if [[ -z "${API_KEY}" ]]; then
  echo "ERROR: API_KEY not found in /root/mailcow-credentials.txt" >&2
  exit 1
fi

echo "==> Setting Full name for ${EMAIL}"
curl -sk -H "X-API-Key: ${API_KEY}" -H "Content-Type: application/json" \
  -X POST https://127.0.0.1/api/v1/edit/mailbox \
  -d "$(python3 -c "import json,os; print(json.dumps({'items':[os.environ['EMAIL']],'attr':{'name':os.environ['NAME']}}))")" \
  | python3 -m json.tool

echo "==> Setting custom attributes title/phone for ${EMAIL}"
curl -sk -H "X-API-Key: ${API_KEY}" -H "Content-Type: application/json" \
  -X POST https://127.0.0.1/api/v1/edit/mailbox/custom-attribute \
  -d "$(python3 -c "import json,os; print(json.dumps({'items':[os.environ['EMAIL']],'attr':{'attribute':['title','phone'],'value':[os.environ['TITLE'],os.environ['PHONE']]}}))")" \
  | python3 -m json.tool

echo "==> Done. Next mail from ${EMAIL} will use these details in the footer."
REMOTE

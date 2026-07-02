#!/usr/bin/env bash
# Local preview — NO Docker. Opens login page in browser.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-8765}"
cd "$ROOT"
echo "Preview: http://localhost:${PORT}/preview/login.html"
echo "Edit branding/mailcow-ui/custom.css and branding/sogo/*.svg then refresh."
python3 -m http.server "$PORT"

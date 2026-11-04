#!/usr/bin/env bash
# Builds "FFXI Login.app" in ~/Applications: a double-clickable launcher that
# runs ffxi-login-macos.sh. Re-run after moving the repo.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
app="${1:-$HOME/Applications/FFXI Login.app}"
mkdir -p "$(dirname "$app")"
log="$HOME/Library/Logs/ffxi-login.log"
osacompile -o "$app" -e "do shell script \"'$repo/scripts/ffxi-login-macos.sh' >> '$log' 2>&1\""
echo "Built $app (output logged to $log)"

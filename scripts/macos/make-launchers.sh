#!/usr/bin/env bash
# Creates double-clickable launchers in ~/Applications:
#   "FFXI Login.command"            logs in
#   "FFXI Login (dry run).command"  checks 1Password access without launching
# A .command file is opened by Terminal itself, so the 1Password CLI runs with
# Terminal's permissions. (AppleScript/Automator applets are silently blocked by
# recent macOS from reading 1Password's data, with no way to approve.)
# Re-run after moving the repo.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dir="${1:-$HOME/Applications}"
mkdir -p "$dir"
make_one() {
    local file="$1" args="$2"
    cat > "$file" <<CMD
#!/bin/bash
'$repo/scripts/ffxi-login-macos.sh' $args
echo
echo "[ffxi-login finished; you can close this window]"
CMD
    chmod +x "$file"
    echo "Created $file"
}
make_one "$dir/FFXI Login.command" ""
make_one "$dir/FFXI Login (dry run).command" "--dry-run"

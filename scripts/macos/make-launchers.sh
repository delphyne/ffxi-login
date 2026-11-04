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
log="$HOME/Library/Logs/ffxi-login.log"
make_one() {
    local file="$1" args="$2" pause="$3"
    cat > "$file" <<CMD
#!/bin/bash
# Output is also appended to $log
'$repo/scripts/ffxi-login-macos.sh' $args 2>&1 | tee -a '$log'
echo
CMD
    if [[ $pause == pause ]]; then
        printf 'read -n 1 -r -s -p "[ffxi-login finished; press any key to close]"\n' >> "$file"
    else
        printf 'echo "[ffxi-login finished]"\n' >> "$file"
    fi
    chmod +x "$file"
    echo "Created $file"
}
make_one "$dir/FFXI Login.command" "" close
make_one "$dir/FFXI Login (dry run).command" "--dry-run" pause

#!/usr/bin/env bash
# Builds "FFXI Login.app" in ~/Applications: a double-clickable launcher for
# ffxi-login-macos.sh. Re-run after moving the repo.
#
#   make-app.sh [--silent] [path/to/App.app] [-- extra wrapper args]
#
# Default: the app opens a Terminal window and runs the wrapper there. Terminal
# normally already holds the macOS "access data from other apps" permission the
# 1Password CLI needs, and you see the log. --silent runs the wrapper directly
# with no window; macOS then asks once to let "FFXI Login" access data from
# other apps, and output goes to ~/Library/Logs/ffxi-login.log.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mode=terminal
app="$HOME/Applications/FFXI Login.app"
extra=""
while (( $# )); do
    case "$1" in
        --silent) mode=silent ;;
        --) shift; extra="$*"; break ;;
        *) app="$1" ;;
    esac
    shift
done
wrapper="$repo/scripts/ffxi-login-macos.sh"
mkdir -p "$(dirname "$app")"
if [[ $mode == terminal ]]; then
    osacompile -o "$app" -e "tell application \"Terminal\"
    activate
    do script \"clear; '$wrapper' $extra; echo; echo '[ffxi-login finished, you can close this window]'\"
end tell"
else
    log="$HOME/Library/Logs/ffxi-login.log"
    osacompile -o "$app" -e "do shell script \"'$wrapper' $extra >> '$log' 2>&1\""
fi
echo "Built $app ($mode mode)"

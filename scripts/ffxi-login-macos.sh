#!/usr/bin/env bash
# Log in to FFXI through CrossOver on macOS, pulling the password from 1Password.
#
# Settings (env or ~/.config/ffxi-login/config):
#   CX_BOTTLE       CrossOver bottle name            (default: ffxi)
#   FFXI_LOGIN_EXE  host path to ffxi-login.exe, which must sit next to Windower.exe
#                   (default: the bottle's Desktop folder)
#   OP_ITEM, OP_PASSWORD_FIELD, OP_OTP_FIELD, CHARACTER   see ffxi-login-common.sh
# Extra arguments are passed to ffxi-login.exe, e.g. --dry-run or --no-proxy.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ffxi-login-common.sh"

: "${CX_BOTTLE:=ffxi}"
: "${CXSTART:=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxstart}"
: "${FFXI_LOGIN_EXE:=$HOME/Library/Application Support/CrossOver/Bottles/$CX_BOTTLE/drive_c/users/crossover/Desktop/ffxi-login.exe}"

[[ -x "$CXSTART" ]] || { echo "ffxi-login: cxstart not found at $CXSTART" >&2; exit 1; }
[[ -f "$FFXI_LOGIN_EXE" ]] || { echo "ffxi-login: exe not found at $FFXI_LOGIN_EXE" >&2; exit 1; }

mapfile -t char_args < <(character_args)
fetch_secrets
emit_secrets | "$CXSTART" --bottle "$CX_BOTTLE" "$FFXI_LOGIN_EXE" "${char_args[@]}" "$@"

#!/usr/bin/env bash
# Log in to FFXI through Lumoria on Linux (SteamOS, Bazzite, ...), pulling the
# password from 1Password. Works as the target of a Steam "non-Steam game"
# shortcut, so it can be launched from Gaming Mode.
#
# Settings (env or ~/.config/ffxi-login/config):
#   LUMORIA_PREFIX  prefix id, from: flatpak run net.windower.Lumoria list   (required)
#   FFXI_LOGIN_EXE  host path to ffxi-login.exe inside that prefix, next to Windower.exe (required)
#   LUMORIA_CMD     launcher command (default: "flatpak run net.windower.Lumoria";
#                   use "lumoria" for a native package install)
#   OP_ITEM, OP_PASSWORD_FIELD, OP_OTP_FIELD, CHARACTER   see ffxi-login-common.sh
# Extra arguments are passed to ffxi-login.exe, e.g. --dry-run or --no-proxy.
#
# Lumoria inherits stdin when it spawns Wine, so the secrets reach the exe
# without touching the environment or the Lumoria logs.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ffxi-login-common.sh"

: "${LUMORIA_PREFIX:?set LUMORIA_PREFIX to the prefix id shown by: flatpak run net.windower.Lumoria list}"
: "${FFXI_LOGIN_EXE:?set FFXI_LOGIN_EXE to the host path of ffxi-login.exe inside the prefix}"
: "${LUMORIA_CMD:=flatpak run net.windower.Lumoria}"

[[ -f "$FFXI_LOGIN_EXE" ]] || { echo "ffxi-login: exe not found at $FFXI_LOGIN_EXE" >&2; exit 1; }

# shellcheck disable=SC2206
lumoria=($LUMORIA_CMD)
mapfile -t char_args < <(character_args)
# Lumoria's --exe starts the program without arguments, so the exe also reads
# options from FFXI_LOGIN_ARGS (non-secret). flatpak needs --env to forward it.
extra_args="${char_args[*]} $*"
if [[ "${lumoria[0]}" == "flatpak" ]]; then
    emit_secrets | "${lumoria[0]}" run "--env=FFXI_LOGIN_ARGS=$extra_args" "${lumoria[@]:2}" launch "$LUMORIA_PREFIX" --exe "$FFXI_LOGIN_EXE"
else
    emit_secrets | FFXI_LOGIN_ARGS="$extra_args" "${lumoria[@]}" launch "$LUMORIA_PREFIX" --exe "$FFXI_LOGIN_EXE"
fi

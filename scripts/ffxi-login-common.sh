# Shared by the platform wrappers. Sourced, not executed.
#
# Reads optional settings from ${XDG_CONFIG_HOME:-~/.config}/ffxi-login/config
# (plain shell assignments), then pulls the secrets from 1Password and prints
# them on stdout in the format ffxi-login.exe expects:
#   line 1: Square Enix password
#   line 2: TOTP secret / otpauth URI, or blank
#
# Only printf (a bash builtin) ever handles the secrets, so they never appear
# in a process's arguments or environment.

set -euo pipefail

CONFIG_FILE="${FFXI_LOGIN_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/ffxi-login/config}"
if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

: "${OP_ITEM:=op://FFXI/Square Enix}"          # 1Password item reference (vault/item)
: "${OP_PASSWORD_FIELD:=password}"             # field holding the Square Enix password
: "${OP_OTP_FIELD:=one-time password}"         # TOTP field; set to "" if you have no security token
: "${CHARACTER:=}"                             # name from config.json; optional if only one is configured

if ! command -v op >/dev/null 2>&1; then
    echo "ffxi-login: 1Password CLI 'op' not found in PATH" >&2
    exit 1
fi

emit_secrets() {
    local pw otp=""
    pw="$(op read "$OP_ITEM/$OP_PASSWORD_FIELD")"
    if [[ -n "$OP_OTP_FIELD" ]]; then
        otp="$(op read "$OP_ITEM/$OP_OTP_FIELD" 2>/dev/null || true)"
    fi
    printf '%s\n%s\n' "$pw" "$otp"
}

character_args() {
    if [[ -n "$CHARACTER" ]]; then
        printf -- '--character\n%s\n' "$CHARACTER"
    fi
}

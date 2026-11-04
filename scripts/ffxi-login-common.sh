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

# GUI launchers (Automator, AppleScript apps, Steam) start with a minimal PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

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

# Fetches the secrets into FFXI_PW / FFXI_OTP (shell variables, not exported)
# and aborts before anything is launched if 1Password cannot be read.
fetch_secrets() {
    FFXI_OTP=""
    if ! FFXI_PW="$(op read "$OP_ITEM/$OP_PASSWORD_FIELD")"; then
        echo "ffxi-login: could not read $OP_ITEM/$OP_PASSWORD_FIELD from 1Password" >&2
        exit 1
    fi
    if [[ -n "$OP_OTP_FIELD" ]]; then
        FFXI_OTP="$(op read "$OP_ITEM/$OP_OTP_FIELD" 2>/dev/null || true)"
    fi
}

# Prints the secrets in the format ffxi-login.exe expects (printf is a builtin,
# so they never appear in any process's arguments).
emit_secrets() {
    printf '%s\n%s\n' "$FFXI_PW" "$FFXI_OTP"
}

character_args() {
    if [[ -n "$CHARACTER" ]]; then
        printf -- '--character\n%s\n' "$CHARACTER"
    fi
}

# ffxi-login

Automates the PlayOnline / Final Fantasy XI login without ever storing your
Square Enix password on disk. A fork of
[jaku/FFXI-autoPOL](https://github.com/jaku/FFXI-autoPOL) built for Wine
hosts (CrossOver on macOS, Lumoria on SteamOS and Bazzite) with the password
and one-time-password secret pulled from 1Password at launch time.

## What changed from upstream

- **No secrets in `config.json`.** Only the character name, PlayOnline slot,
  Windower arguments and timing live there. Secrets are read from **standard
  input**, one per line: the Square Enix password, then the TOTP secret or
  `otpauth://` URI (blank if you have no security token). From a terminal you
  are prompted instead, with echo off. The secrets are overwritten in memory
  once typed.
- **Typed, not pasted.** Upstream pastes the password via the Windows
  clipboard; under Wine that clipboard is shared with the host desktop, so this
  fork types it key by key (`typeDelay` ms per character).
- **Wine aware.** Under Wine the prefix hosts file is left alone, because Wine
  resolves names through the host. The one-line host entry below replaces it.
- **`FFXI_LOGIN_ARGS`** supplies command-line options for launchers that
  cannot pass arguments (Lumoria's `--exe`).
- **`--dry-run`** reads the secrets, prints their lengths and the current TOTP
  code, and exits without launching anything.
- Cross-compiles with mingw-w64 (`make`), so the exe can be built on the Mac
  or Linux box it will run from. The Visual Studio project is still there but
  unmaintained.

Everything else (slot navigation, the `wh000.pol.com` proxy that skips the
PlayOnline main menu, multi-character support, troubleshooting) is upstream's
work; see its README for the long form.

## How it works

```
op read ... ──pipe──▶ ffxi-login.exe (inside the Wine prefix)
                        ├─ starts Windower.exe
                        ├─ waits for the PlayOnline Viewer window
                        ├─ picks the slot, types the password and TOTP code
                        └─ serves one fake PML page so PlayOnline goes straight to the game
```

The host wrapper fetches the secrets with the 1Password CLI and pipes them in.
A pipe is a private descriptor between the two processes, so the password
never appears in a process list, in the environment, or in Lumoria's logs.
Wine passes stdin through to Windows console programs (verified on CrossOver
26.3; Lumoria inherits stdin when it spawns Wine).

## Setup

### 1. 1Password item

Create an item (the wrappers default to vault `FFXI`, item `Square Enix`) with:

- `password`: your **Square Enix account** password. This is what PlayOnline
  asks for at login once the PlayOnline password itself has been saved in the
  viewer, which is how the retail client works for everyone.
- `one-time password`: only if you use a security token. Square Enix's token
  registration offers "Other authenticator apps"; scan that QR code into
  1Password (or paste the secret). `op read` returns an `otpauth://` URI and
  the exe extracts the secret from it. Skip this field otherwise.

Install the 1Password CLI and turn on **Settings → Developer → Integrate with
1Password CLI** in the desktop app, so `op read` unlocks with Touch ID or the
system authentication prompt.

### 2. Build or download the exe

```sh
brew install mingw-w64        # macOS
make                          # produces dist/ffxi-login.exe (32-bit, static)
```

### 3. Install into the prefix

Copy `dist/ffxi-login.exe` **next to `Windower.exe`** (or `pol.exe`). Then,
from a terminal, run the setup once to create `config.json`:

```sh
# macOS / CrossOver
/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine --bottle ffxi \
  "$HOME/Library/Application Support/CrossOver/Bottles/ffxi/drive_c/users/crossover/Desktop/ffxi-login.exe" --setup
```

Setup asks for the client region, the delay before typing starts, the delay
between typed characters, and for each character a name, the PlayOnline slot
(1-20; 5+ needs Windower) and optional Windower arguments. Nothing secret.

### 4. Host entry for the main-menu skip

PlayOnline loads its main menu over plain HTTP from `wh000.pol.com`; the exe
answers that request locally with a page that jumps straight into the game.
Point the name at loopback once per machine:

```sh
echo "127.0.0.1 wh000.pol.com" | sudo tee -a /etc/hosts
```

While that line exists you must log in through this tool (or remove the line).
Pass `--no-proxy` to skip the trick and click Play yourself.

### 5. Wrapper

Copy `scripts/config.example` to `~/.config/ffxi-login/config` and edit it.

**macOS / CrossOver**

```sh
scripts/ffxi-login-macos.sh              # log in
scripts/ffxi-login-macos.sh --dry-run    # check the plumbing first
```

**Lumoria (SteamOS, Bazzite)**

```sh
flatpak run net.windower.Lumoria list    # find the prefix id
LUMORIA_PREFIX=ffxi FFXI_LOGIN_EXE="$HOME/Games/Lumoria/ffxi/drive_c/.../Windower/ffxi-login.exe" \
  scripts/ffxi-login-lumoria.sh --dry-run
```

Add the wrapper script as a non-Steam game to launch it from Gaming Mode.
Note that the 1Password desktop-app integration unlocks through a polkit
prompt, which Gaming Mode may not show; unlock 1Password in Desktop Mode
first, or use a 1Password service account limited to a read-only vault that
holds only this item.

## Command line

```
ffxi-login.exe [--character NAME] [--no-proxy] [--dry-run] [--debug-keys]
ffxi-login.exe --setup | --edit          (interactive, needs a terminal)
```

Options may also be given in `FFXI_LOGIN_ARGS`, whitespace separated. With
several characters configured and no terminal, `--character` is required.

`config.json` keys: `delay` (ms before typing starts, default 3000),
`typeDelay` (ms per typed character, default 20), `clientRegion` (`US`, `JP`,
`EU`), and `accounts[]` with `name`, `slot`, `args`. A `password` or
`totpSecret` key is ignored with a warning; delete them.

## Troubleshooting

- **Missing or extra characters in the password**: raise `delay` first, then
  `typeDelay`. Upstream notes the cursor sometimes starts on the `0` key.
- **Login stops at the PlayOnline main menu**: the `/etc/hosts` line is
  missing or the proxy port (51304 US/EU, 51300 JP) is in use.
- **Nothing is typed**: the viewer window must have focus; a controller that
  is enabled in PlayOnline can interfere. Disable PlayOnline's own auto-login.
- **`No password supplied on stdin`**: the wrapper's `op read` failed. Run
  `op read "op://FFXI/Square Enix/password"` by hand to see the real error.

## License

MIT, as upstream. Original work by jaku; fork changes by Brian M. Carr.

#!/bin/bash
set -Eeuo pipefail
APP="Boat Simulator"
fail(){ printf '\nERROR: %s\n' "$1" >&2; exit 1; }
printf '\n=== BOAT SIMULATOR INSTALLER ===\n'
[[ "$(/usr/bin/uname -s)" == Darwin ]] || fail "macOS only."
V="$(/usr/bin/sw_vers -productVersion)"; M="${V%%.*}"
[[ "$M" =~ ^[0-9]+$ ]] && (( M >= 11 )) || fail "Requires macOS 11 or newer; found $V."
T="$(/usr/bin/mktemp -d)"; trap '/bin/rm -rf "$T"' EXIT
URL="https://github.com/ttmeticks-source/Boat-simulator/releases/download/latest/Boat-Simulator-macOS.zip"
printf 'Downloading the prebuilt universal macOS app...\n'
/usr/bin/curl --fail --location --silent --show-error --retry 3 "$URL" -o "$T/Boat-Simulator.zip" || fail "The app release has not been published yet."
/usr/bin/unzip -q "$T/Boat-Simulator.zip" -d "$T" || fail "Could not unpack the app archive."
[[ -d "$T/Boat Simulator.app" ]] || fail "Archive did not contain Boat Simulator.app."
DEST="$HOME/Applications"
/bin/mkdir -p "$DEST"
/bin/rm -rf "$DEST/$APP.app"
/usr/bin/ditto "$T/Boat Simulator.app" "$DEST/$APP.app"
printf '\nInstalled: %s/%s.app\n' "$DEST" "$APP"
printf 'This installer does not compile anything or require Xcode/Command Line Tools.\n'
/usr/bin/open "$DEST/$APP.app"

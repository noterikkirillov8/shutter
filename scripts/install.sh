#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Erik's local identity when present; ad-hoc signing for everyone else.
IDENTITY="Erik Local Signing"
security find-identity -v -p codesigning | grep -q "$IDENTITY" || IDENTITY="-"

scripts/build.sh Release CODE_SIGN_IDENTITY="$IDENTITY"
codesign --verify --strict build/Build/Products/Release/Shutter.app
if pgrep -x Shutter >/dev/null; then echo 'Quit Shutter before installing.' >&2; exit 1; fi
ditto build/Build/Products/Release/Shutter.app /Applications/Shutter.app
[[ -n ${NO_OPEN:-} ]] || open /Applications/Shutter.app

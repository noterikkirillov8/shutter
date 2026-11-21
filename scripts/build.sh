#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/{home,tmp,cache}
export TMPDIR="$PWD/build/tmp/" CFFIXED_USER_HOME="$PWD/build/home" CLANG_MODULE_CACHE_PATH="$PWD/build/cache"
xcodegen generate -s Shutter/project.yml >/dev/null
flags=()
if [[ ${CODEX_SANDBOX:-} == seatbelt ]]; then flags+=('OTHER_SWIFT_FLAGS=$(inherited) -Xfrontend -disable-sandbox'); fi
xcodebuild -project Shutter/Shutter.xcodeproj -scheme Shutter -configuration "${1:-Debug}" -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath "$PWD/build" -disableAutomaticPackageResolution COMPILER_INDEX_STORE_ENABLE=NO ${flags[@]+"${flags[@]}"} "${@:2}" -quiet build

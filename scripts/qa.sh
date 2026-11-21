#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build.sh Debug
export TMPDIR="$PWD/build/tmp/" CFFIXED_USER_HOME="$PWD/build/home" CLANG_MODULE_CACHE_PATH="$PWD/build/cache"
build/Build/Products/Debug/Shutter.app/Contents/MacOS/Shutter -qa "$PWD/qa"
python3 scripts/verify-qa.py

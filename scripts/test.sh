#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/{tmp,cache,home}
export TMPDIR="$PWD/build/tmp/" CLANG_MODULE_CACHE_PATH="$PWD/build/cache" CFFIXED_USER_HOME="$PWD/build/home"
if grep -En 'import (AppKit|Cocoa|SwiftUI|ApplicationServices|ScreenCaptureKit)|NS(Window|Panel|Application|StatusBar)|CG(Event|WindowList)|AXUIElement' Shutter/Sources/Core/*.swift Tests/*.swift; then exit 1; fi
swiftc -swift-version 6 -module-cache-path "$PWD/build/cache" Shutter/Sources/Core/*.swift Tests/*.swift -o build/fixture-tests
build/fixture-tests
echo 'PASS  isolated executable: no live adapter, event posting, or window code compiled'

#!/bin/bash
# Generates Resources/AppIcon.icns from scripts/make-icon.swift.
# Run when you change the icon design; the .icns is committed and build.sh just copies it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Rendering 1024px master"
swift "$ROOT/scripts/make-icon.swift" "$TMP/icon_1024.png"

echo "==> Building iconset"
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"
gen() { sips -z "$1" "$1" "$TMP/icon_1024.png" --out "$SET/$2" >/dev/null; }
gen 16   "icon_16x16.png"
gen 32   "icon_16x16@2x.png"
gen 32   "icon_32x32.png"
gen 64   "icon_32x32@2x.png"
gen 128  "icon_128x128.png"
gen 256  "icon_128x128@2x.png"
gen 256  "icon_256x256.png"
gen 512  "icon_256x256@2x.png"
gen 512  "icon_512x512.png"
gen 1024 "icon_512x512@2x.png"

mkdir -p "$ROOT/Resources"
iconutil -c icns "$SET" -o "$ROOT/Resources/AppIcon.icns"
echo "==> Wrote Resources/AppIcon.icns"

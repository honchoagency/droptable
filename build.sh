#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Droptable"
BUNDLE_ID="com.honcho.Droptable"
APP_BUNDLE="$ROOT/${APP_NAME}.app"

cd "$ROOT"

# Version from the latest git tag (e.g. v1.2.0 → 1.2.0), fallback 1.0.
# Override with VERSION_OVERRIDE=1.0.0 to test the update checker locally.
VERSION="${VERSION_OVERRIDE:-$(git -C "$ROOT" describe --tags --abbrev=0 2>/dev/null || true)}"
VERSION="${VERSION:-1.0}"
VERSION="${VERSION#v}"

if [ "${UNIVERSAL:-0}" = "1" ]; then
  echo "==> swift build (release, universal arm64+x86_64)"
  swift build -c release --product Droptable --arch arm64 --arch x86_64
  BUILD_BIN="$ROOT/.build/apple/Products/Release/Droptable"
else
  echo "==> swift build (release, $(uname -m))"
  swift build -c release --product Droptable
  BUILD_BIN="$ROOT/.build/release/Droptable"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
ICON_LINE=""
if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
  ICON_LINE="    <key>CFBundleIconFile</key><string>AppIcon</string>"
fi

# Derive "owner/repo" from the git remote so the in-app update check knows
# where to look (blank if there's no GitHub remote → update check silently
# disabled, e.g. before this project has been pushed anywhere).
REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
REPO="$(printf '%s' "$REMOTE" | sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')"
GHREPO_LINE=""
if printf '%s' "$REPO" | grep -qE '^[^/]+/[^/]+$'; then
  GHREPO_LINE="    <key>GHRepo</key><string>$REPO</string>"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
$ICON_LINE
$GHREPO_LINE
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© Honcho</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Droptable scans your Desktop folder for old database dump files.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Droptable scans your Documents folder for old database dump files.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>Droptable scans your Downloads folder for old database dump files.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"

echo "Built $APP_BUNDLE (v$VERSION) — run: open $APP_BUNDLE"

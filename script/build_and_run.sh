#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CleanMac"
BUNDLE_ID="com.luoguoqiu.CleanMac"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
PKG_INFO="$APP_CONTENTS/PkgInfo"
APP_ICON_SOURCE="$ROOT_DIR/Sources/CleanMac/Resources/Images/cleanmac-mascot.png"
APP_ICONSET="$DIST_DIR/$APP_NAME.iconset"
APP_ICON="$APP_RESOURCES/$APP_NAME.icns"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
BUILD_UNIVERSAL="${BUILD_UNIVERSAL:-0}"
APP_VERSION="${CLEANMAC_VERSION:-0.0.0}"
APP_BUILD_NUMBER="${CLEANMAC_BUILD_NUMBER:-0}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

case "$MODE" in
  run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--bundle|bundle) ;;
  *)
    echo "usage: $0 [run|bundle|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

case "$BUILD_CONFIGURATION" in
  debug|release) ;;
  *) fail "BUILD_CONFIGURATION must be debug or release" ;;
esac
case "$BUILD_UNIVERSAL" in
  0|1) ;;
  *) fail "BUILD_UNIVERSAL must be 0 or 1" ;;
esac
[[ "$APP_VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] \
  || fail "CLEANMAC_VERSION must contain two or three numeric components"
[[ "$APP_BUILD_NUMBER" =~ ^[0-9]+$ ]] \
  || fail "CLEANMAC_BUILD_NUMBER must be a non-negative integer"
if [ "$BUILD_UNIVERSAL" = "1" ] && [ "$BUILD_CONFIGURATION" != "release" ]; then
  fail "universal app bundles must use BUILD_CONFIGURATION=release"
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"

if [ "$BUILD_UNIVERSAL" = "1" ]; then
  ARM_SCRATCH="$ROOT_DIR/.build/universal-release-arm64"
  X86_SCRATCH="$ROOT_DIR/.build/universal-release-x86_64"
  ARM_TRIPLE="arm64-apple-macosx14.0"
  X86_TRIPLE="x86_64-apple-macosx14.0"

  swift build -c release --product "$APP_NAME" --triple "$ARM_TRIPLE" --scratch-path "$ARM_SCRATCH"
  swift build -c release --product "$APP_NAME" --triple "$X86_TRIPLE" --scratch-path "$X86_SCRATCH"
  ARM_BUILD_DIR="$(swift build -c release --triple "$ARM_TRIPLE" --scratch-path "$ARM_SCRATCH" --show-bin-path)"
  X86_BUILD_DIR="$(swift build -c release --triple "$X86_TRIPLE" --scratch-path "$X86_SCRATCH" --show-bin-path)"

  /usr/bin/lipo -create \
    "$ARM_BUILD_DIR/$APP_NAME" \
    "$X86_BUILD_DIR/$APP_NAME" \
    -output "$APP_BINARY"
  RESOURCE_BUILD_DIR="$ARM_BUILD_DIR"
else
  swift build -c "$BUILD_CONFIGURATION" --product "$APP_NAME"
  RESOURCE_BUILD_DIR="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)"
  cp "$RESOURCE_BUILD_DIR/$APP_NAME" "$APP_BINARY"
fi
chmod +x "$APP_BINARY"
printf 'APPL????' >"$PKG_INFO"

if [ -f "$APP_ICON_SOURCE" ]; then
  rm -rf "$APP_ICONSET"
  mkdir -p "$APP_ICONSET"
  for ICON_SIZE in 16 32 128 256 512; do
    sips -z "$ICON_SIZE" "$ICON_SIZE" "$APP_ICON_SOURCE" --out "$APP_ICONSET/icon_${ICON_SIZE}x${ICON_SIZE}.png" >/dev/null
    DOUBLE_SIZE=$((ICON_SIZE * 2))
    sips -z "$DOUBLE_SIZE" "$DOUBLE_SIZE" "$APP_ICON_SOURCE" --out "$APP_ICONSET/icon_${ICON_SIZE}x${ICON_SIZE}@2x.png" >/dev/null
  done
  iconutil -c icns "$APP_ICONSET" -o "$APP_ICON"
  rm -rf "$APP_ICONSET"
else
  echo "warning: app icon source not found at $APP_ICON_SOURCE" >&2
fi

# Place SwiftPM resource bundles under Contents/Resources so Bundle.module can
# resolve them from the assembled app bundle.
for RESOURCE_BUNDLE in "$RESOURCE_BUILD_DIR"/CleanMac_*.bundle; do
  [ -d "$RESOURCE_BUNDLE" ] || continue
  cp -R "$RESOURCE_BUNDLE" "$APP_RESOURCES/"
done

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconName</key>
  <string>$APP_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSQuitAlwaysKeepsWindows</key>
  <false/>
</dict>
</plist>
PLIST

plutil -lint "$INFO_PLIST" >/dev/null
if [ "$BUILD_UNIVERSAL" = "1" ]; then
  "$ROOT_DIR/script/verify_release.sh" "$APP_BUNDLE"
fi

touch "$APP_BUNDLE"

open_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f "$APP_BUNDLE" >/dev/null 2>&1 || true
  fi
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --bundle|bundle)
    echo "$APP_BUNDLE"
    ;;
esac

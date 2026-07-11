#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CleanMac"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/dist/$APP_NAME.app}"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[ -d "$APP_BUNDLE" ] || fail "app bundle not found: $APP_BUNDLE"
[ -f "$INFO_PLIST" ] || fail "Info.plist not found: $INFO_PLIST"
[ -x "$APP_BINARY" ] || fail "app executable not found: $APP_BINARY"

plutil -lint "$INFO_PLIST" >/dev/null
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"

[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] \
  || fail "invalid CFBundleShortVersionString: $VERSION"
[[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] \
  || fail "invalid CFBundleVersion: $BUILD_NUMBER"

ARCHITECTURES="$(/usr/bin/lipo -archs "$APP_BINARY")"
case " $ARCHITECTURES " in
  *" arm64 "*) ;;
  *) fail "release executable is missing arm64: $ARCHITECTURES" ;;
esac
case " $ARCHITECTURES " in
  *" x86_64 "*) ;;
  *) fail "release executable is missing x86_64: $ARCHITECTURES" ;;
esac

SOURCE_ARTWORK="$(find "$APP_RESOURCES" -type f -name '*-key.png' -print -quit)"
[ -z "$SOURCE_ARTWORK" ] || fail "source artwork was packaged: $SOURCE_ARTWORK"
[ ! -d "$APP_RESOURCES/ImagesSource" ] || fail "ImagesSource was packaged"

printf 'Verified %s %s (%s), architectures: %s\n' \
  "$APP_NAME" "$VERSION" "$BUILD_NUMBER" "$ARCHITECTURES"

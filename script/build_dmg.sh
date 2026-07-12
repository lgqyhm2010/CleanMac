#!/usr/bin/env bash
set -euo pipefail

# Build a universal release DMG. The default --release mode fails closed unless
# Developer ID signing and notarization are fully configured. --unsigned is an
# explicit, non-distributable preview path for local and pull-request testing.

MODE="${1:---release}"
APP_NAME="CleanMac"
VOL_NAME="CleanMac"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
ENTITLEMENTS="$ROOT_DIR/script/$APP_NAME.entitlements"

log() {
  printf '\033[1;34m[build_dmg]\033[0m %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_environment() {
  local name="$1"
  [ -n "${!name:-}" ] || fail "$name is required for a distributable release"
}

case "$MODE" in
  --release|release) UNSIGNED=0 ;;
  --unsigned|unsigned) UNSIGNED=1 ;;
  *)
    echo "usage: $0 [--release|--unsigned]" >&2
    exit 2
    ;;
esac

if [ "$UNSIGNED" = "1" ]; then
  VERSION="${CLEANMAC_VERSION:-0.0.0}"
  BUILD_NUMBER="${CLEANMAC_BUILD_NUMBER:-0}"
  CODESIGN_IDENTITY="-"
  log "Building an unsigned preview; this artifact is not for distribution."
else
  require_environment CLEANMAC_VERSION
  require_environment CLEANMAC_BUILD_NUMBER
  VERSION="$CLEANMAC_VERSION"
  BUILD_NUMBER="$CLEANMAC_BUILD_NUMBER"

  if [ -z "${CODESIGN_IDENTITY:-}" ]; then
    CODESIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
      | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' \
      | head -1)"
  fi
  case "$CODESIGN_IDENTITY" in
    "Developer ID Application:"*) ;;
    *) fail "a Developer ID Application signing identity is required" ;;
  esac

  if [ -z "${NOTARY_PROFILE:-}" ]; then
    require_environment APPLE_ID
    require_environment APPLE_TEAM_ID
    require_environment APPLE_APP_PASSWORD
  fi
fi

log "Building universal $APP_NAME.app ($VERSION, build $BUILD_NUMBER)…"
BUILD_CONFIGURATION=release \
BUILD_UNIVERSAL=1 \
CLEANMAC_VERSION="$VERSION" \
CLEANMAC_BUILD_NUMBER="$BUILD_NUMBER" \
  "$ROOT_DIR/script/build_and_run.sh" bundle >/dev/null
[ -d "$APP_BUNDLE" ] || fail "$APP_BUNDLE was not produced"
"$ROOT_DIR/script/verify_release.sh" "$APP_BUNDLE"

SIGN_ARGS=(--force --deep --sign "$CODESIGN_IDENTITY")
if [ "$UNSIGNED" = "0" ]; then
  SIGN_ARGS+=(--options runtime --timestamp)
  [ -f "$ENTITLEMENTS" ] && SIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
fi

log "Signing app with identity: $CODESIGN_IDENTITY"
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

log "Packaging DMG…"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGING" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null

if [ "$UNSIGNED" = "1" ]; then
  log "Created unsigned preview: $DMG_PATH"
  exit 0
fi

log "Signing DMG…"
codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

log "Submitting DMG for notarization…"
if [ -n "${NOTARY_PROFILE:-}" ]; then
  NOTARY_RESULT="$(xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --output-format json)"
else
  NOTARY_RESULT="$(xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait \
    --output-format json)"
fi
printf '%s\n' "$NOTARY_RESULT"
NOTARY_STATUS="$(printf '%s' "$NOTARY_RESULT" | plutil -extract status raw -o - -)"
[ "$NOTARY_STATUS" = "Accepted" ] \
  || fail "notarization did not finish as Accepted (status: $NOTARY_STATUS)"

log "Stapling and validating notarization ticket…"
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

log "Created signed, notarized release: $DMG_PATH"

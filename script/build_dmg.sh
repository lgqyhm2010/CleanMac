#!/usr/bin/env bash
set -euo pipefail

# build_dmg.sh — Build CleanMac.app and package it into a distributable .dmg.
#
# The DMG is SIGNED and NOTARIZED when Developer ID credentials are available,
# and DEGRADES GRACEFULLY (ad-hoc signature) otherwise so it always produces an
# artifact. No secrets are ever hard-coded — everything comes from the keychain
# or environment variables.
#
# Optional environment variables:
#   CODESIGN_IDENTITY   Signing identity, e.g. "Developer ID Application: Name (TEAMID)".
#                       Auto-detected from the keychain when unset. Set to "-" to
#                       force an ad-hoc signature.
#   NOTARY_PROFILE      A notarytool keychain profile created once with:
#                         xcrun notarytool store-credentials <profile> \
#                           --apple-id you@example.com --team-id TEAMID \
#                           --password <app-specific-password>
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD
#                       Notarization credentials for CI (used instead of a profile).
#   SKIP_NOTARIZE=1     Build and sign, but skip notarization.
#
# See docs/RELEASING.md for the one-time Developer ID / notarization setup.

APP_NAME="CleanMac"
VOL_NAME="CleanMac"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
ENTITLEMENTS="$ROOT_DIR/script/$APP_NAME.entitlements"   # optional

log()  { printf '\033[1;34m[build_dmg]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[build_dmg] warning:\033[0m %s\n' "$*" >&2; }

# 1. Build the .app bundle (reuses build_and_run.sh's bundle assembly).
log "Building $APP_NAME.app…"
"$ROOT_DIR/script/build_and_run.sh" bundle >/dev/null
[ -d "$APP_BUNDLE" ] || { echo "error: $APP_BUNDLE was not produced" >&2; exit 1; }

# 2. Resolve a signing identity.
if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  DEVID="$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"$/\1/' || true)"
  CODESIGN_IDENTITY="${DEVID:--}"   # fall back to ad-hoc ("-")
fi

SIGN_ARGS=(--force --deep --sign "$CODESIGN_IDENTITY")
DISTRIBUTABLE=0
if [ "$CODESIGN_IDENTITY" = "-" ]; then
  warn "No Developer ID Application certificate found — using an AD-HOC signature."
  warn "This DMG is fine for local testing but is NOT distributable or notarizable."
else
  case "$CODESIGN_IDENTITY" in
    "Developer ID Application"*) DISTRIBUTABLE=1 ;;
    *) warn "Signing with a non-Developer-ID identity ($CODESIGN_IDENTITY); notarization will be skipped." ;;
  esac
  # Hardened runtime + secure timestamp are required for notarization.
  SIGN_ARGS+=(--options runtime --timestamp)
  [ -f "$ENTITLEMENTS" ] && SIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
fi

# 3. Sign the app.
log "Signing app with identity: $CODESIGN_IDENTITY"
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" || warn "codesign verify reported issues"

# 4. Build the DMG (staging dir with an Applications drag-target).
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
log "Created $DMG_PATH"

# 5. Sign the DMG itself (only meaningful with a real identity).
if [ "$CODESIGN_IDENTITY" != "-" ]; then
  codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$DMG_PATH"
fi

# 6. Notarize + staple when possible.
notarize() {
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_APP_PASSWORD:-}" ]; then
    xcrun notarytool submit "$DMG_PATH" \
      --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
  else
    return 2
  fi
}

if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
  warn "SKIP_NOTARIZE=1 — skipping notarization."
elif [ "$DISTRIBUTABLE" != "1" ]; then
  warn "Not notarizing: no Developer ID Application identity in use."
else
  log "Submitting for notarization (this can take a few minutes)…"
  if notarize; then
    log "Stapling notarization ticket…"
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH" && log "Notarized and stapled."
  else
    warn "No notarization credentials (set NOTARY_PROFILE, or APPLE_ID/APPLE_TEAM_ID/APPLE_APP_PASSWORD)."
    warn "DMG is signed but NOT notarized. See docs/RELEASING.md."
  fi
fi

log "Done: $DMG_PATH"

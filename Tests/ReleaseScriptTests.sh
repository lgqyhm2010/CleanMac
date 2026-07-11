#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/script" "$FIXTURE/fake-bin" "$FIXTURE/dist"
cp "$ROOT_DIR/script/build_dmg.sh" "$FIXTURE/script/build_dmg.sh"
chmod +x "$FIXTURE/script/build_dmg.sh"

cat >"$FIXTURE/script/build_and_run.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT_DIR/dist/CleanMac.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
printf 'fixture' >"$APP/Contents/MacOS/CleanMac"
chmod +x "$APP/Contents/MacOS/CleanMac"
printf '%s\n' "$APP"
SCRIPT

cat >"$FIXTURE/script/verify_release.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
[ -d "$1" ]
SCRIPT

cat >"$FIXTURE/fake-bin/codesign" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
arguments=" $* "
target="${*: -1}"
if [[ "$arguments" == *" --verify "* ]]; then
  if [[ "$target" == *.app ]] && [ "${FAIL_STAGE:-}" = "app-verify" ]; then exit 31; fi
  if [[ "$target" == *.dmg ]] && [ "${FAIL_STAGE:-}" = "dmg-verify" ]; then exit 32; fi
elif [[ "$target" == *.app ]] && [ "${FAIL_STAGE:-}" = "app-sign" ]; then
  exit 33
elif [[ "$target" == *.dmg ]] && [ "${FAIL_STAGE:-}" = "dmg-sign" ]; then
  exit 34
fi
SCRIPT

cat >"$FIXTURE/fake-bin/hdiutil" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
[ "${FAIL_STAGE:-}" != "dmg-create" ] || exit 35
touch "${*: -1}"
SCRIPT

cat >"$FIXTURE/fake-bin/xcrun" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-} ${2:-}" in
  "notarytool submit")
    [ "${FAIL_STAGE:-}" != "notary-command" ] || exit 36
    if [ "${FAIL_STAGE:-}" = "notary-status" ]; then
      printf '%s\n' '{"id":"fixture","status":"Invalid"}'
    else
      printf '%s\n' '{"id":"fixture","status":"Accepted"}'
    fi
    ;;
  "stapler staple")
    [ "${FAIL_STAGE:-}" != "staple" ] || exit 37
    ;;
  "stapler validate")
    [ "${FAIL_STAGE:-}" != "stapler-validate" ] || exit 38
    ;;
  *) exit 39 ;;
esac
SCRIPT

cat >"$FIXTURE/fake-bin/spctl" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
[ "${FAIL_STAGE:-}" != "gatekeeper" ] || exit 40
SCRIPT

chmod +x \
  "$FIXTURE/script/build_and_run.sh" \
  "$FIXTURE/script/verify_release.sh" \
  "$FIXTURE/fake-bin/codesign" \
  "$FIXTURE/fake-bin/hdiutil" \
  "$FIXTURE/fake-bin/xcrun" \
  "$FIXTURE/fake-bin/spctl"

run_release() {
  env \
    PATH="$FIXTURE/fake-bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    CLEANMAC_VERSION=1.2.3 \
    CLEANMAC_BUILD_NUMBER=42 \
    CODESIGN_IDENTITY="Developer ID Application: Fixture (TEAMID1234)" \
    APPLE_ID=fixture@example.invalid \
    APPLE_TEAM_ID=TEAMID1234 \
    APPLE_APP_PASSWORD=fixture-password \
    FAIL_STAGE="${1:-}" \
    "$FIXTURE/script/build_dmg.sh" --release
}

run_release "" >/dev/null

for stage in \
  app-sign \
  app-verify \
  dmg-create \
  dmg-sign \
  dmg-verify \
  notary-command \
  notary-status \
  staple \
  stapler-validate \
  gatekeeper
do
  if run_release "$stage" >"$FIXTURE/$stage.log" 2>&1; then
    printf 'error: release succeeded after injected %s failure\n' "$stage" >&2
    exit 1
  fi
done

if env \
  PATH="$FIXTURE/fake-bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  CLEANMAC_VERSION=1.2.3 \
  CLEANMAC_BUILD_NUMBER=42 \
  CODESIGN_IDENTITY="Developer ID Application: Fixture (TEAMID1234)" \
  "$FIXTURE/script/build_dmg.sh" --release >"$FIXTURE/missing-notary.log" 2>&1
then
  echo "error: release succeeded without notarization credentials" >&2
  exit 1
fi

printf 'release fail-closed harness passed\n'

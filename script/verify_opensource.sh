#!/usr/bin/env bash
set -uo pipefail

# verify_opensource.sh — Check that the open-source deliverables are all present
# and that the package still builds. Exit non-zero if anything is missing.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOCALES=(zh-Hans zh-Hant ja es fr ar hi pt-BR ru bn)   # all non-English locales
fail=0

check_file() {
  if [ -f "$1" ]; then
    echo "  ok   $1"
  else
    echo "  MISS $1"
    fail=1
  fi
}

echo "== docs =="
check_file LICENSE
check_file README.md
check_file CONTRIBUTING.md
check_file docs/RELEASING.md
for loc in "${LOCALES[@]}"; do
  check_file "README.${loc}.md"
done

echo "== scripts =="
check_file script/build_dmg.sh
if [ -x script/build_dmg.sh ]; then echo "  ok   script/build_dmg.sh is executable"; else echo "  MISS script/build_dmg.sh not executable"; fail=1; fi

echo "== ci =="
check_file .github/workflows/release-dmg.yml

echo "== swift build =="
if env CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" swift build --product CleanMac >/tmp/cleanmac_verify_build.log 2>&1; then
  echo "  ok   swift build --product CleanMac"
else
  echo "  FAIL swift build (see /tmp/cleanmac_verify_build.log)"
  tail -20 /tmp/cleanmac_verify_build.log
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "ALL OPEN-SOURCE CHECKS PASSED"
else
  echo "SOME CHECKS FAILED"
fi
exit "$fail"

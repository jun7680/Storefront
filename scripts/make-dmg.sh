#!/usr/bin/env bash
#
# Storefront.app → Storefront-<version>.dmg
# create-dmg가 있으면 더 예쁜 DMG (Applications 심볼릭 링크, 배경, 레이아웃)
# 없으면 hdiutil fallback.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/export/Storefront.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo "dev")
DMG="$BUILD_DIR/Storefront-${VERSION}.dmg"

if [ ! -d "$APP" ]; then
  echo "ERROR: $APP not found. Run scripts/build.sh first." >&2
  exit 1
fi

rm -f "$DMG"

if command -v create-dmg >/dev/null 2>&1; then
  echo "==> create-dmg"
  create-dmg \
    --volname "Storefront ${VERSION}" \
    --window-pos 200 120 \
    --window-size 640 380 \
    --icon-size 100 \
    --icon "Storefront.app" 180 180 \
    --app-drop-link 460 180 \
    --hide-extension "Storefront.app" \
    --no-internet-enable \
    --skip-jenkins \
    "$DMG" \
    "$APP" \
    || {
      # create-dmg는 가끔 cosmetic 에러로 실패하지만 DMG는 생성됨 — 존재 여부로 재검증
      if [ ! -f "$DMG" ]; then
        echo "ERROR: create-dmg 실패, DMG 미생성" >&2
        exit 1
      fi
    }
else
  echo "==> hdiutil (create-dmg 미설치)"
  STAGING="$BUILD_DIR/dmg-staging"
  rm -rf "$STAGING"
  mkdir -p "$STAGING"
  cp -R "$APP" "$STAGING/"
  ln -s /Applications "$STAGING/Applications"
  hdiutil create \
    -volname "Storefront ${VERSION}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG"
  rm -rf "$STAGING"
fi

echo "==> DMG ready: $DMG"
ls -lh "$DMG"

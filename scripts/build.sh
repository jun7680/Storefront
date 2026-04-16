#!/usr/bin/env bash
#
# 로컬 릴리스 빌드 — Storefront.xcarchive → Storefront.app (ad-hoc 서명)
#
# 사전 요건:
#   brew install xcodegen create-dmg
#   xcodegen generate
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Storefront.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS="$ROOT/scripts/ExportOptions.plist"

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "==> xcodebuild archive"
xcodebuild archive \
  -project Storefront.xcodeproj \
  -scheme Storefront \
  -configuration Release \
  -destination 'platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$BUILD_DIR" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_HARDENED_RUNTIME=NO \
  | xcbeautify 2>/dev/null || true

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo "ERROR: archive not produced at $ARCHIVE_PATH" >&2
  exit 1
fi

echo "==> xcodebuild -exportArchive"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  | xcbeautify 2>/dev/null || true

APP="$EXPORT_PATH/Storefront.app"
if [ ! -d "$APP" ]; then
  echo "ERROR: export missing $APP" >&2
  exit 1
fi

echo "==> ad-hoc codesign"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP"

echo "==> Storefront.app ready at: $APP"

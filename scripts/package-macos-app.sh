#!/usr/bin/env bash
# Собирает релиз и упаковывает минимальный .app для распространения без Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v swift &>/dev/null; then
  echo "swift не найден в PATH" >&2
  exit 1
fi

if ! command -v sips &>/dev/null || ! command -v iconutil &>/dev/null; then
  echo "Нужны утилиты sips и iconutil (macOS)." >&2
  exit 1
fi

if ! command -v codesign &>/dev/null; then
  echo "codesign не найден (ожидается macOS)." >&2
  exit 1
fi

MARKETING_VERSION="${MARKETING_VERSION:-$(
  grep -E 'marketingVersion = "' Sources/CleanerCore/AppMetadata.swift | head -1 | sed 's/.*"\([^"]*\)".*/\1/'
)}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_ID="${BUNDLE_ID:-com.github.miwist.MacosStorageCleaner}"

ICON_SOURCE="${ROOT}/packaging/AppIconSource.png"
if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "Нет исходника иконки: $ICON_SOURCE" >&2
  exit 1
fi

swift build -c release

BIN="$(swift build -c release --show-bin-path)/MacosStorageCleaner"
if [[ ! -f "$BIN" ]]; then
  echo "Не найден бинарник: $BIN" >&2
  exit 1
fi

APP_NAME="MacosStorageCleaner.app"
STAGE="${ROOT}/.build/PackageStaging"
APP_PATH="${STAGE}/${APP_NAME}"
ICONSET="${STAGE}/AppIcon.iconset"

rm -rf "$STAGE"
mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/Resources"
cp "$BIN" "${APP_PATH}/Contents/MacOS/MacosStorageCleaner"
chmod +x "${APP_PATH}/Contents/MacOS/MacosStorageCleaner"

mkdir -p "$ICONSET"
sips -z 16 16 "$ICON_SOURCE" --out "${ICONSET}/icon_16x16.png" &>/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "${ICONSET}/icon_16x16@2x.png" &>/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "${ICONSET}/icon_32x32.png" &>/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "${ICONSET}/icon_32x32@2x.png" &>/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "${ICONSET}/icon_128x128.png" &>/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "${ICONSET}/icon_128x128@2x.png" &>/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "${ICONSET}/icon_256x256.png" &>/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "${ICONSET}/icon_256x256@2x.png" &>/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "${ICONSET}/icon_512x512.png" &>/dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "${ICONSET}/icon_512x512@2x.png" &>/dev/null
iconutil -c icns "$ICONSET" -o "${APP_PATH}/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

cat >"${APP_PATH}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>ru</string>
	<key>CFBundleExecutable</key>
	<string>MacosStorageCleaner</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Очистка хранилища</string>
	<key>CFBundleDisplayName</key>
	<string>Очистка хранилища</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${MARKETING_VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD_NUMBER}</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © Miwist. Лицензия MIT.</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_PATH"

ARCHIVE_NAME="MacosStorageCleaner-${MARKETING_VERSION}-macos.zip"
OUT_ZIP="${ROOT}/.build/${ARCHIVE_NAME}"
STABLE_ZIP="${ROOT}/.build/MacosStorageCleaner-macos.zip"

rm -f "$OUT_ZIP" "$STABLE_ZIP"
export COPYFILE_DISABLE=1
(
  cd "$STAGE"
  zip -r -X "$OUT_ZIP" "$APP_NAME"
)
cp "$OUT_ZIP" "$STABLE_ZIP"

echo "Готово: $OUT_ZIP"
echo "Копия для README и releases/latest/download: $STABLE_ZIP"
echo "Распакуйте архив и перетащите $APP_NAME в «Программы»."

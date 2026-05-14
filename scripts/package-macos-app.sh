#!/usr/bin/env bash
# Собирает релиз и упаковывает минимальный .app для распространения без Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v swift &>/dev/null; then
  echo "swift не найден в PATH" >&2
  exit 1
fi

MARKETING_VERSION="${MARKETING_VERSION:-$(
  grep -E 'marketingVersion = "' Sources/CleanerCore/AppMetadata.swift | head -1 | sed 's/.*"\([^"]*\)".*/\1/'
)}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_ID="${BUNDLE_ID:-com.github.miwist.MacosStorageCleaner}"

swift build -c release

BIN="$(swift build -c release --show-bin-path)/MacosStorageCleaner"
if [[ ! -f "$BIN" ]]; then
  echo "Не найден бинарник: $BIN" >&2
  exit 1
fi

APP_NAME="MacosStorageCleaner.app"
STAGE="${ROOT}/.build/PackageStaging"
APP_PATH="${STAGE}/${APP_NAME}"

rm -rf "$STAGE"
mkdir -p "${APP_PATH}/Contents/MacOS"
cp "$BIN" "${APP_PATH}/Contents/MacOS/MacosStorageCleaner"
chmod +x "${APP_PATH}/Contents/MacOS/MacosStorageCleaner"

cat >"${APP_PATH}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>ru</string>
	<key>CFBundleExecutable</key>
	<string>MacosStorageCleaner</string>
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

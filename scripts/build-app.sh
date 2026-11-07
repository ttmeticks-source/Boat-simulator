#!/bin/bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="${VERSION:-1.0.0}"
export MACOSX_DEPLOYMENT_TARGET=11.0
mkdir -p "$ROOT/build"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
for ARCH in arm64 x86_64; do
  xcrun swiftc -parse-as-library -O -sdk "$SDK" -target "${ARCH}-apple-macosx11.0" \
    -framework AppKit -framework SpriteKit -framework SwiftUI \
    Sources/BoatSimulator/main.swift -o "$ROOT/build/BoatSimulator-$ARCH"
done
lipo -create "$ROOT/build/BoatSimulator-arm64" "$ROOT/build/BoatSimulator-x86_64" -output "$ROOT/build/BoatSimulator"
APP="$ROOT/build/Boat Simulator.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ -f "$ROOT/Assets/BoatSimulator.icns.base64" ]]; then
  base64 -D -i "$ROOT/Assets/BoatSimulator.icns.base64" -o "$APP/Contents/Resources/BoatSimulator.icns"
fi
cp "$ROOT/build/BoatSimulator" "$APP/Contents/MacOS/BoatSimulator"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Boat Simulator</string>
<key>CFBundleDisplayName</key><string>Boat Simulator</string>
<key>CFBundleIdentifier</key><string>com.ttmeticks.boatsimulator</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleExecutable</key><string>BoatSimulator</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>CFBundleIconFile</key><string>BoatSimulator</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP" >/dev/null
echo "Built universal app: $APP"

#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
APP="dist/BK Clock.app"
mkdir -p "$APP/Contents/MacOS"
clang++ -std=c++17 -O2 -fobjc-arc -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 src/mac.mm -framework Cocoa -o "$APP/Contents/MacOS/BK Clock"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BK Clock</string>
<key>CFBundleIdentifier</key><string>app.bkclock.desktop</string>
<key>CFBundleName</key><string>BK Clock</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>NSHighResolutionCapable</key><true/>
<key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/BK-Clock-macOS.zip"
echo "Built $APP"

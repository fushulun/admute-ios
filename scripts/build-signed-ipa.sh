#!/usr/bin/env bash
# 生成已签名 IPA：需要 macOS + Xcode + 已登录的 Apple 开发者账号。
# 用法：TEAM_ID=ABCDE12345 ./scripts/build-signed-ipa.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${TEAM_ID:-}" ]; then
  echo "请先设置 TEAM_ID，例如：TEAM_ID=ABCDE12345 ./scripts/build-signed-ipa.sh"
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "缺少 XcodeGen，请先执行：brew install xcodegen"
  exit 1
fi

xcodegen generate

rm -rf build dist
mkdir -p dist

xcodebuild \
  -project AdMute.xcodeproj \
  -scheme AdMute \
  -configuration Release \
  -sdk iphoneos \
  -archivePath build/AdMute.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive

cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>development</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>
PLIST

xcodebuild \
  -exportArchive \
  -archivePath build/AdMute.xcarchive \
  -exportPath dist \
  -exportOptionsPlist build/ExportOptions.plist

echo "完成：dist/ 目录下的 .ipa"

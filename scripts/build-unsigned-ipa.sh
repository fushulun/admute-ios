#!/usr/bin/env bash
# 生成未签名 IPA：不需要 Apple 账号，产物用于 Sideloadly / AltStore 自签安装。
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "缺少 XcodeGen，请先执行：brew install xcodegen"
  exit 1
fi

xcodegen generate

rm -rf build dist
mkdir -p dist/Payload

xcodebuild \
  -project AdMute.xcodeproj \
  -scheme AdMute \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

cp -R build/Build/Products/Release-iphoneos/AdMute.app dist/Payload/
(cd dist && zip -qr AdMute-unsigned.ipa Payload)

echo "完成：dist/AdMute-unsigned.ipa"
echo "下一步：用 Sideloadly 或 AltStore 以你自己的 Apple ID 签名安装。"

#!/bin/bash

# SpaceLauncher 打包脚本
# 创建 .app bundle 并签名，解决辅助功能权限持久化问题

set -e

APP_NAME="SpaceLauncher"
BUILD_DIR=".build/debug"
APP_DIR="build"
APP_BUNDLE="${APP_DIR}/${APP_NAME}.app"

echo "📦 Building ${APP_NAME}..."

# 编译项目
swift build

echo "🎨 Generating app icon..."

# 生成图标
swift GenerateIcon.swift

# 转换为 icns
iconutil -c icns "${APP_DIR}/SpaceLauncher.iconset" -o "${APP_DIR}/SpaceLauncher.icns"

echo "📁 Creating app bundle structure..."

# 创建 bundle 目录结构
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"

# 复制可执行文件
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# 复制图标文件
cp "${APP_DIR}/SpaceLauncher.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# 创建 Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.spacelauncher.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighProcessCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
</dict>
</plist>
EOF

# 创建 PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "🔐 Signing app bundle..."

# 签名应用（使用 ad-hoc 签名，开发阶段）
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ App bundle created: ${APP_BUNDLE}"
echo ""
echo "📋 To install:"
echo "   cp -r ${APP_BUNDLE} /Applications/"
echo ""
echo "⚠️ Note: Ad-hoc signature may still require re-authorization after system updates."
echo "   For permanent solution, use a proper Developer ID certificate."
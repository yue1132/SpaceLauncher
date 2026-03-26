#!/bin/bash

# SpaceLauncher 打包脚本
# 将Swift编译产物打包成macOS应用包

set -e

APP_NAME="SpaceLauncher"
APP_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔧 Building ${APP_NAME}..."

# 编译发布版本
swift build -c release

echo "📦 Creating app bundle..."

# 创建应用包目录结构
rm -rf build
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 复制可执行文件
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/"

# 复制Info.plist
cp "Resources/Info.plist" "${CONTENTS_DIR}/"

# 复制entitlements
cp "Resources/SpaceLauncher.entitlements" "${CONTENTS_DIR}/"

# 创建PkgInfo
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# 生成应用图标
echo "🎨 Generating app icon..."

# 使用Swift生成图标
cat > /tmp/generate_icon.swift << 'SWIFTCODE'
import AppKit

let size = NSSize(width: 512, height: 512)
let image = NSImage(size: size)

image.lockFocus()

// 背景渐变
let gradient = NSGradient(colors: [NSColor.systemBlue, NSColor.systemPurple])
let rect = NSRect(origin: .zero, size: size)
let path = NSBezierPath(roundedRect: rect, xRadius: size.width * 0.2)
gradient?.draw(in: path, angle: 45)

// 键盘图标
let config = NSImage.SymbolConfiguration(pointSize: 200, weight: .light)
if let keyboardImage = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)?
    .withSymbolConfiguration(config)?
    .tinted(with: .white) {

    let imageSize = keyboardImage.size
    let x = (size.width - imageSize.width) / 2
    let y = (size.height - imageSize.height) / 2 - 20
    keyboardImage.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)
}

// Space文字
let font = NSFont.systemFont(ofSize: 80, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
let text = "Space" as NSString
let textSize = text.size(withAttributes: attrs)
let textX = (size.width - textSize.width) / 2
let textY = 80
text.draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)

image.unlockFocus()

// 保存为icns
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {

    // 创建iconset目录
    let iconsetPath = "/tmp/SpaceLauncher.iconset"
    try? FileManager.default.removeItem(atPath: iconsetPath)
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    // 生成不同尺寸
    let sizes: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]

    for (size, scale) in sizes {
        let scaledImage = NSImage(size: NSSize(width: size, height: size))
        scaledImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: NSSize(width: size, height: size)))
        scaledImage.unlockFocus()

        if let tiff = scaledImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {

            let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
            try? png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
        }
    }

    // 使用iconutil生成icns
    let task = Process()
    task.launchPath = "/usr/bin/iconutil"
    task.arguments = ["-c", "icns", "-o", "/tmp/SpaceLauncher.icns", iconsetPath]
    try? task.run()
    task.waitUntilExit()
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
SWIFTCODE

swift /tmp/generate_icon.swift 2>/dev/null || true

# 复制图标
if [ -f "/tmp/SpaceLauncher.icns" ]; then
    cp "/tmp/SpaceLauncher.icns" "${RESOURCES_DIR}/AppIcon.icns"
    echo "✅ Icon created"
else
    echo "⚠️  Icon generation failed, using default"
fi

echo ""
echo "✅ Build complete!"
echo "📁 App location: $(pwd)/${APP_DIR}"
echo ""
echo "🚀 To run the app:"
echo "   open ${APP_DIR}"
echo ""
echo "⚙️  To install the app:"
echo "   cp -r ${APP_DIR} /Applications/"
echo ""
echo "🔑 IMPORTANT: Grant Accessibility permission in System Settings → Privacy & Security → Accessibility"
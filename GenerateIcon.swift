import AppKit
import CoreGraphics
import Foundation

// 生成 SpaceLauncher 应用图标
// 设计理念：键盘 + 发射火箭，象征快捷键启动应用

func createIcon(size: Int) -> NSImage? {
    let scale: CGFloat = CGFloat(size)
    let image = NSImage(size: NSSize(width: scale, height: scale))

    image.lockFocus()

    // 获取当前 graphics context
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return nil
    }

    // 背景 - 蓝紫色渐变圆角矩形
    let bgRect = CGRect(x: 0, y: 0, width: scale, height: scale)
    let cornerRadius = scale * 0.2

    // 创建渐变
    let colors = [
        CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0),
        CGColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0)
    ]
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: [0.0, 1.0]) else {
        image.unlockFocus()
        return nil
    }

    // 绘制圆角背景
    let bgPath = CGPath(roundedRect: bgRect.insetBy(dx: 2, dy: 2),
                        cornerWidth: cornerRadius,
                        cornerHeight: cornerRadius,
                        transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: 0),
                           end: CGPoint(x: scale, y: scale),
                           options: [])

    ctx.resetClip()

    // 键盘主体 - 白色圆角矩形
    let keyboardWidth = scale * 0.6
    let keyboardHeight = scale * 0.45
    let keyboardX = (scale - keyboardWidth) / 2
    let keyboardY = scale * 0.1

    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    let keyboardPath = CGPath(roundedRect: CGRect(x: keyboardX, y: keyboardY,
                                                   width: keyboardWidth, height: keyboardHeight),
                              cornerWidth: scale * 0.08,
                              cornerHeight: scale * 0.08,
                              transform: nil)
    ctx.addPath(keyboardPath)
    ctx.fillPath()

    // 绘制按键网格 (3行 x 4列)
    let keySize = scale * 0.08
    let keySpacing = scale * 0.12
    let keysStartX = keyboardX + (keyboardWidth - 4 * keySpacing + keySize) / 2
    let keysStartY = keyboardY + (keyboardHeight - 3 * keySpacing + keySize) / 2

    ctx.setFillColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5))

    for row in 0..<3 {
        for col in 0..<4 {
            let keyX = keysStartX + CGFloat(col) * keySpacing
            let keyY = keysStartY + CGFloat(row) * keySpacing
            let keyPath = CGPath(roundedRect: CGRect(x: keyX, y: keyY, width: keySize, height: keySize),
                                  cornerWidth: scale * 0.01,
                                  cornerHeight: scale * 0.01,
                                  transform: nil)
            ctx.addPath(keyPath)
            ctx.fillPath()
        }
    }

    // Space 键 - 蓝色突出
    let spaceWidth = scale * 0.35
    let spaceHeight = scale * 0.06
    let spaceX = (scale - spaceWidth) / 2
    let spaceY = keyboardY + keyboardHeight - spaceHeight - scale * 0.03

    ctx.setFillColor(CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0))
    let spacePath = CGPath(roundedRect: CGRect(x: spaceX, y: spaceY, width: spaceWidth, height: spaceHeight),
                           cornerWidth: scale * 0.01,
                           cornerHeight: scale * 0.01,
                           transform: nil)
    ctx.addPath(spacePath)
    ctx.fillPath()

    // 发射火箭 - 在键盘上方
    let rocketY = scale * 0.6

    // 火箭背景圆 - 橙黄渐变
    let rocketCircleRadius = scale * 0.15
    let rocketCenterX = scale / 2
    let rocketCenterY = rocketY

    let rocketColors = [
        CGColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
        CGColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
    ]
    guard let rocketGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: rocketColors as CFArray,
                                            locations: [0.0, 1.0]) else {
        image.unlockFocus()
        return nil
    }

    ctx.drawRadialGradient(rocketGradient,
                           startCenter: CGPoint(x: rocketCenterX, y: rocketCenterY + rocketCircleRadius * 0.5),
                           startRadius: 0,
                           endCenter: CGPoint(x: rocketCenterX, y: rocketCenterY),
                           endRadius: rocketCircleRadius,
                           options: [])

    // 火箭图标 - 白色三角形
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))

    // 简化的火箭形状
    let rocketPath = CGMutablePath()
    // 火箭头部（三角形）
    rocketPath.move(to: CGPoint(x: rocketCenterX, y: rocketCenterY + scale * 0.1))
    rocketPath.addLine(to: CGPoint(x: rocketCenterX - scale * 0.05, y: rocketCenterY - scale * 0.05))
    rocketPath.addLine(to: CGPoint(x: rocketCenterX + scale * 0.05, y: rocketCenterY - scale * 0.05))
    rocketPath.closeSubpath()

    ctx.addPath(rocketPath)
    ctx.fillPath()

    // 火箭尾翼
    let leftFin = CGMutablePath()
    leftFin.move(to: CGPoint(x: rocketCenterX - scale * 0.05, y: rocketCenterY - scale * 0.05))
    leftFin.addLine(to: CGPoint(x: rocketCenterX - scale * 0.08, y: rocketCenterY - scale * 0.08))
    leftFin.addLine(to: CGPoint(x: rocketCenterX - scale * 0.05, y: rocketCenterY - scale * 0.02))
    leftFin.closeSubpath()
    ctx.addPath(leftFin)
    ctx.fillPath()

    let rightFin = CGMutablePath()
    rightFin.move(to: CGPoint(x: rocketCenterX + scale * 0.05, y: rocketCenterY - scale * 0.05))
    rightFin.addLine(to: CGPoint(x: rocketCenterX + scale * 0.08, y: rocketCenterY - scale * 0.08))
    rightFin.addLine(to: CGPoint(x: rocketCenterX + scale * 0.05, y: rocketCenterY - scale * 0.02))
    rightFin.closeSubpath()
    ctx.addPath(rightFin)
    ctx.fillPath()

    // 发射光效 - 向上的线条
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8))
    ctx.setLineWidth(scale * 0.02)
    for i in 0..<3 {
        let lineX = rocketCenterX + CGFloat(i - 1) * scale * 0.03
        ctx.move(to: CGPoint(x: lineX, y: rocketCenterY - scale * 0.08))
        ctx.addLine(to: CGPoint(x: lineX, y: rocketCenterY - scale * 0.15))
        ctx.strokePath()
    }

    image.unlockFocus()
    return image
}

// 创建 iconset 目录
let iconsetPath = "build/SpaceLauncher.iconset"
let fileManager = FileManager.default

if fileManager.fileExists(atPath: iconsetPath) {
    try fileManager.removeItem(atPath: iconsetPath)
}
try fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// 生成各个尺寸的图标
let sizes: [(size: Int, filename: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for spec in sizes {
    guard let icon = createIcon(size: spec.size),
          let tiffData = icon.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ Failed to create \(spec.filename)")
        continue
    }

    try pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(spec.filename)"))
    print("✅ Created \(spec.filename) (\(spec.size)x\(spec.size))")
}

print("🎨 Icon set created at: \(iconsetPath)")
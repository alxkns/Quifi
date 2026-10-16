import AppKit
import CoreGraphics

guard CommandLine.arguments.count >= 3 else {
    print("Usage: create_app_icon <input_jpg> <output_png> [crop_x] [crop_y] [crop_w] [crop_h]")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let srcImage = NSImage(contentsOfFile: inputPath),
      let srcRep = srcImage.representations.first else {
    print("❌ Failed to load input image: \(inputPath)")
    exit(1)
}

let srcW = CGFloat(srcRep.pixelsWide)
let srcH = CGFloat(srcRep.pixelsHigh)

// Default crop box for the AI generated squircle centered at ~512,512
var cropX: CGFloat = 205
var cropY: CGFloat = 205
var cropW: CGFloat = 612
var cropH: CGFloat = 612

if CommandLine.arguments.count >= 7 {
    cropX = CGFloat(Double(CommandLine.arguments[3]) ?? 205)
    cropY = CGFloat(Double(CommandLine.arguments[4]) ?? 205)
    cropW = CGFloat(Double(CommandLine.arguments[5]) ?? 612)
    cropH = CGFloat(Double(CommandLine.arguments[6]) ?? 612)
}

let canvasSize: CGFloat = 1024
let targetSize: CGFloat = 824
let targetPadding: CGFloat = (canvasSize - targetSize) / 2.0 // 100.0
let cornerRadius: CGFloat = 185.0 // Apple standard corner radius for 824x824 squircle

// Create RGBA bitmap
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil,
    width: Int(canvasSize),
    height: Int(canvasSize),
    bitsPerComponent: 8,
    bytesPerRow: Int(canvasSize) * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("❌ Failed to create CGContext")
    exit(1)
}

// Enable highest quality rendering
ctx.interpolationQuality = .high
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

// Convert NSImage to CGImage
guard let cgSrc = srcImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("❌ Failed to get CGImage")
    exit(1)
}

// Crop the inner squircle tile from the source
// Note: CGImage coordinates have (0,0) at top-left
let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
guard let croppedTile = cgSrc.cropping(to: cropRect) else {
    print("❌ Failed to crop tile")
    exit(1)
}

// Target squircle rect on the 1024x1024 canvas
let tileRect = CGRect(x: targetPadding, y: targetPadding, width: targetSize, height: targetSize)
let squirclePath = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// 1. Draw subtle macOS app icon drop shadow
ctx.saveGState()
let shadowColor = NSColor.black.withAlphaComponent(0.28).cgColor
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: shadowColor)
ctx.addPath(squirclePath)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// 2. Draw cropped image clipped to squircle path
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()
ctx.draw(croppedTile, in: tileRect)

// 3. Draw subtle inner border highlight (Apple style)
ctx.addPath(squirclePath)
ctx.setLineWidth(1.5)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
ctx.strokePath()
ctx.restoreGState()

// Export to PNG
guard let finalCgImage = ctx.makeImage() else {
    print("❌ Failed to create final CGImage")
    exit(1)
}

let finalBitmap = NSBitmapImageRep(cgImage: finalCgImage)
guard let pngData = finalBitmap.representation(using: .png, properties: [:]) else {
    print("❌ Failed to convert to PNG")
    exit(1)
}

let outURL = URL(fileURLWithPath: outputPath)
try pngData.write(to: outURL)
print("✅ Saved masked transparent icon to \(outputPath)")

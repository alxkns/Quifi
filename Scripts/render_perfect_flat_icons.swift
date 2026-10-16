import AppKit
import CoreGraphics

let canvasSize: CGFloat = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func makeSquircle(in rect: CGRect, radius: CGFloat = 185) -> CGPath {
    return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawSquircleTile(in ctx: CGContext, fillColor: NSColor) {
    let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squirclePath = makeSquircle(in: squircleRect)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: NSColor.black.withAlphaComponent(0.18).cgColor)
    ctx.addPath(squirclePath)
    ctx.setFillColor(fillColor.cgColor)
    ctx.fillPath()
    ctx.restoreGState()
}

// -------------------------------------------------------------
// 1. Blue Squircle + White Folder Silhouette + Cutout Lightning
// -------------------------------------------------------------
func renderConcept1() -> CGImage {
    let ctx = CGContext(data: nil, width: Int(canvasSize), height: Int(canvasSize), bitsPerComponent: 8, bytesPerRow: Int(canvasSize) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // Solid Apple Blue (#007AFF) - No gradient
    drawSquircleTile(in: ctx, fillColor: NSColor(srgbRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0))

    let cX: CGFloat = 512
    let cY: CGFloat = 512
    let fW: CGFloat = 500
    let fH: CGFloat = 360
    let fX = cX - fW / 2
    let fY = cY - fH / 2 - 10

    let folder = CGMutablePath()
    let r: CGFloat = 24
    let tabW: CGFloat = 180
    let tabH: CGFloat = 42

    // Smooth Apple-style folder path
    folder.move(to: CGPoint(x: fX + r, y: fY))
    folder.addLine(to: CGPoint(x: fX + fW - r, y: fY))
    folder.addArc(tangent1End: CGPoint(x: fX + fW, y: fY), tangent2End: CGPoint(x: fX + fW, y: fY + r), radius: r)
    folder.addLine(to: CGPoint(x: fX + fW, y: fY + fH - tabH))
    folder.addArc(tangent1End: CGPoint(x: fX + fW, y: fY + fH - tabH), tangent2End: CGPoint(x: fX + fW - r, y: fY + fH - tabH), radius: 14)
    folder.addLine(to: CGPoint(x: fX + tabW + 22, y: fY + fH - tabH))
    folder.addArc(tangent1End: CGPoint(x: fX + tabW + 6, y: fY + fH), tangent2End: CGPoint(x: fX + tabW - 10, y: fY + fH), radius: 14)
    folder.addLine(to: CGPoint(x: fX + r, y: fY + fH))
    folder.addArc(tangent1End: CGPoint(x: fX, y: fY + fH), tangent2End: CGPoint(x: fX, y: fY + fH - r), radius: r)
    folder.addLine(to: CGPoint(x: fX, y: fY + r))
    folder.addArc(tangent1End: CGPoint(x: fX, y: fY), tangent2End: CGPoint(x: fX + r, y: fY), radius: r)
    folder.closeSubpath()

    // Crisp lightning bolt cutout
    let bolt = CGMutablePath()
    let bCX: CGFloat = cX
    let bCY: CGFloat = fY + (fH - tabH) / 2
    let scale: CGFloat = 17.0

    bolt.move(to: CGPoint(x: bCX + 1.2 * scale, y: bCY + 7.5 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 6.2 * scale, y: bCY - 1.2 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 0.5 * scale, y: bCY - 1.2 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 2.2 * scale, y: bCY - 8.2 * scale))
    bolt.addLine(to: CGPoint(x: bCX + 6.2 * scale, y: bCY + 0.8 * scale))
    bolt.addLine(to: CGPoint(x: bCX + 0.5 * scale, y: bCY + 0.8 * scale))
    bolt.closeSubpath()

    folder.addPath(bolt)

    ctx.addPath(folder)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath(using: .evenOdd)

    return ctx.makeImage()!
}

// -------------------------------------------------------------
// 2. Pure Lightning Glyph (Shortcuts/VoiceMemos Style)
// -------------------------------------------------------------
func renderConcept2() -> CGImage {
    let ctx = CGContext(data: nil, width: Int(canvasSize), height: Int(canvasSize), bitsPerComponent: 8, bytesPerRow: Int(canvasSize) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // Solid Apple System Blue (#007AFF)
    drawSquircleTile(in: ctx, fillColor: NSColor(srgbRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0))

    let cX: CGFloat = 512
    let cY: CGFloat = 512
    let scale: CGFloat = 26.0

    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: cX + 2.0 * scale, y: cY + 9.5 * scale))
    bolt.addLine(to: CGPoint(x: cX - 8.2 * scale, y: cY - 1.8 * scale))
    bolt.addLine(to: CGPoint(x: cX - 0.5 * scale, y: cY - 1.8 * scale))
    bolt.addLine(to: CGPoint(x: cX - 3.2 * scale, y: cY - 10.5 * scale))
    bolt.addLine(to: CGPoint(x: cX + 8.2 * scale, y: cY + 1.0 * scale))
    bolt.addLine(to: CGPoint(x: cX + 0.5 * scale, y: cY + 1.0 * scale))
    bolt.closeSubpath()

    ctx.addPath(bolt)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()

    return ctx.makeImage()!
}

// -------------------------------------------------------------
// 3. Two-Tone Flat macOS Folder with White Lightning Stamped
// -------------------------------------------------------------
func renderConcept3() -> CGImage {
    let ctx = CGContext(data: nil, width: Int(canvasSize), height: Int(canvasSize), bitsPerComponent: 8, bytesPerRow: Int(canvasSize) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // Neutral macOS tile or dark blue tile
    drawSquircleTile(in: ctx, fillColor: NSColor(srgbRed: 0.05, green: 0.35, blue: 0.75, alpha: 1.0))

    let cX: CGFloat = 512
    let cY: CGFloat = 512
    let fW: CGFloat = 530
    let fH: CGFloat = 390
    let fX = cX - fW / 2
    let fY = cY - fH / 2 - 10

    // Back Tab (Solid Flat Blue #4AA5FB)
    let backFolder = CGMutablePath()
    let r: CGFloat = 24
    let tabW: CGFloat = 195
    let tabH: CGFloat = 50

    backFolder.move(to: CGPoint(x: fX + r, y: fY + 40))
    backFolder.addLine(to: CGPoint(x: fX + fW - r, y: fY + 40))
    backFolder.addArc(tangent1End: CGPoint(x: fX + fW, y: fY + 40), tangent2End: CGPoint(x: fX + fW, y: fY + fH - tabH), radius: r)
    backFolder.addLine(to: CGPoint(x: fX + fW, y: fY + fH - tabH))
    backFolder.addArc(tangent1End: CGPoint(x: fX + fW, y: fY + fH - 8), tangent2End: CGPoint(x: fX + fW - 8, y: fY + fH - 8), radius: 12)
    backFolder.addLine(to: CGPoint(x: fX + tabW + 24, y: fY + fH - 8))
    backFolder.addArc(tangent1End: CGPoint(x: fX + tabW + 6, y: fY + fH), tangent2End: CGPoint(x: fX + tabW - 8, y: fY + fH), radius: 14)
    backFolder.addLine(to: CGPoint(x: fX + r, y: fY + fH))
    backFolder.addArc(tangent1End: CGPoint(x: fX, y: fY + fH), tangent2End: CGPoint(x: fX, y: fY + fH - r), radius: r)
    backFolder.addLine(to: CGPoint(x: fX, y: fY + 40 + r))
    backFolder.addArc(tangent1End: CGPoint(x: fX, y: fY + 40), tangent2End: CGPoint(x: fX + r, y: fY + 40), radius: r)
    backFolder.closeSubpath()

    ctx.addPath(backFolder)
    ctx.setFillColor(NSColor(srgbRed: 0.31, green: 0.65, blue: 0.98, alpha: 1.0).cgColor) // #4FA5FB
    ctx.fillPath()

    // Front Body (Solid Flat Blue #1E82EE)
    let frontH: CGFloat = 290
    let frontBody = CGMutablePath()
    frontBody.addRoundedRect(in: CGRect(x: fX - 4, y: fY, width: fW + 8, height: frontH), cornerWidth: 24, cornerHeight: 24)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: NSColor.black.withAlphaComponent(0.20).cgColor)
    ctx.addPath(frontBody)
    ctx.setFillColor(NSColor(srgbRed: 0.12, green: 0.51, blue: 0.93, alpha: 1.0).cgColor) // #1E82EE
    ctx.fillPath()
    ctx.restoreGState()

    // Crisp White Lightning Bolt
    let bolt = CGMutablePath()
    let bCX: CGFloat = cX
    let bCY: CGFloat = fY + frontH / 2
    let scale: CGFloat = 16.0

    bolt.move(to: CGPoint(x: bCX + 1.2 * scale, y: bCY + 6.8 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 5.8 * scale, y: bCY - 1.0 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 0.5 * scale, y: bCY - 1.0 * scale))
    bolt.addLine(to: CGPoint(x: bCX - 2.0 * scale, y: bCY - 7.5 * scale))
    bolt.addLine(to: CGPoint(x: bCX + 5.8 * scale, y: bCY + 0.8 * scale))
    bolt.addLine(to: CGPoint(x: bCX + 0.5 * scale, y: bCY + 0.8 * scale))
    bolt.closeSubpath()

    ctx.addPath(bolt)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()

    return ctx.makeImage()!
}

func save(img: CGImage, name: String) {
    let rep = NSBitmapImageRep(cgImage: img)
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    let path = "docs/images/concepts/\(name).png"
    try? data.write(to: URL(fileURLWithPath: path))
    print("Exported \(path)")
}

save(img: renderConcept1(), name: "flat_apple_v1_classic")
save(img: renderConcept2(), name: "flat_apple_v2_pure_bolt")
save(img: renderConcept3(), name: "flat_apple_v3_two_tone_folder")

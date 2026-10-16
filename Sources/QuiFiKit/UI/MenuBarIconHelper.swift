import AppKit

public enum MenuBarIconHelper {
    public static func icon(for style: MenuBarIconStyle) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        switch style {
        case .quifiLightning:
            return makeQuiFiLightningIcon()
        case .folderSparkles:
            let img = NSImage(systemSymbolName: "folder.badge.sparkles", accessibilityDescription: "QuiFi")?.withSymbolConfiguration(config) ?? NSImage()
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        case .dropTray:
            let img = NSImage(systemSymbolName: "tray.and.arrow.down.fill", accessibilityDescription: "QuiFi")?.withSymbolConfiguration(config) ?? NSImage()
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        case .cascadingStack:
            let img = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "QuiFi")?.withSymbolConfiguration(config) ?? NSImage()
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        case .speedArrow:
            let img = NSImage(systemSymbolName: "arrow.right.circle.fill", accessibilityDescription: "QuiFi")?.withSymbolConfiguration(config) ?? NSImage()
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            return img
        }
    }

    public static func makeQuiFiLightningIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current?.cgContext

            let folderPath = CGMutablePath()

            // Folder tab
            folderPath.move(to: CGPoint(x: 2.0, y: 12.0))
            folderPath.addLine(to: CGPoint(x: 2.0, y: 13.5))
            folderPath.addArc(tangent1End: CGPoint(x: 2.0, y: 15.0), tangent2End: CGPoint(x: 3.5, y: 15.0), radius: 1.2)
            folderPath.addLine(to: CGPoint(x: 6.5, y: 15.0))
            folderPath.addArc(tangent1End: CGPoint(x: 8.0, y: 15.0), tangent2End: CGPoint(x: 9.0, y: 13.5), radius: 1.2)
            folderPath.addLine(to: CGPoint(x: 9.5, y: 12.5))
            folderPath.addLine(to: CGPoint(x: 14.5, y: 12.5))
            folderPath.addArc(tangent1End: CGPoint(x: 16.0, y: 12.5), tangent2End: CGPoint(x: 16.0, y: 11.0), radius: 1.2)

            // Folder body
            folderPath.addLine(to: CGPoint(x: 16.0, y: 3.5))
            folderPath.addArc(tangent1End: CGPoint(x: 16.0, y: 2.0), tangent2End: CGPoint(x: 14.5, y: 2.0), radius: 1.2)
            folderPath.addLine(to: CGPoint(x: 3.5, y: 2.0))
            folderPath.addArc(tangent1End: CGPoint(x: 2.0, y: 2.0), tangent2End: CGPoint(x: 2.0, y: 3.5), radius: 1.2)
            folderPath.closeSubpath()

            // Draw lightning bolt cutout inside folder
            let boltPath = CGMutablePath()
            boltPath.move(to: CGPoint(x: 9.6, y: 11.2))
            boltPath.addLine(to: CGPoint(x: 6.4, y: 6.8))
            boltPath.addLine(to: CGPoint(x: 8.8, y: 6.8))
            boltPath.addLine(to: CGPoint(x: 8.2, y: 3.2))
            boltPath.addLine(to: CGPoint(x: 11.8, y: 7.6))
            boltPath.addLine(to: CGPoint(x: 9.4, y: 7.6))
            boltPath.closeSubpath()

            folderPath.addPath(boltPath)

            ctx?.addPath(folderPath)
            NSColor.black.setFill()
            ctx?.fillPath(using: .evenOdd)

            return true
        }
        image.isTemplate = true
        return image
    }
}

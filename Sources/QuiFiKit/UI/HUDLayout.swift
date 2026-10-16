import Foundation
import CoreGraphics

public enum HUDLayout {
    /// Width of an individual column box
    public static let columnWidth: CGFloat = 200
    
    /// Gap between adjacent columns
    public static let columnSpacing: CGFloat = 12
    
    /// Horizontal padding of the outer frosted glass card
    public static let cardPaddingHorizontal: CGFloat = 14
    
    /// Vertical padding
    public static let cardPaddingTop: CGFloat = 10
    public static let cardPaddingBottom: CGFloat = 14
    
    /// Height of the HUD panel
    public static let targetHeight: CGFloat = 350
    
    /// Maximum scrollable height for folders in a column
    public static let columnScrollMaxHeight: CGFloat = 260
    
    /// Total width of the outer frosted glass card for a given column count
    public static func cardWidth(forColumnCount count: Int) -> CGFloat {
        let n = CGFloat(max(1, count))
        return (n * columnWidth) + ((n - 1) * columnSpacing) + (cardPaddingHorizontal * 2)
    }
}

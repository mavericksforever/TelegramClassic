import Cocoa
import TGUIKit

public struct MediaGridStyle: InterfaceStyleVariants {
    public let fillsWidth: Bool

    public var tileCornerRadius: CGFloat {
        return fillsWidth ? 0 : .cornerRadius
    }

    public static let liquidGlass = MediaGridStyle(
        fillsWidth: false
    )

    public static let classic = MediaGridStyle(
        fillsWidth: true
    )
}

import Cocoa
import TGUIKit

struct MediaPreviewEditStyle: InterfaceStyleVariants {
    enum Surface {
        case glass(cornerRadius: CGFloat)
        case capsule(NSColor)
    }

    let surface: Surface

    static let liquidGlass = MediaPreviewEditStyle(
        surface: .glass(cornerRadius: 8)
    )

    static let classic = MediaPreviewEditStyle(
        surface: .capsule(.blackTransparent)
    )
}

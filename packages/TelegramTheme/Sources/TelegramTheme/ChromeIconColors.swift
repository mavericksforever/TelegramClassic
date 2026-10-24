import Cocoa
import TGUIKit
import ColorPalette

public struct ChromeIconColors: InterfaceStyleVariants {
    public let primary: (ColorPalette) -> NSColor
    public let secondary: (ColorPalette) -> NSColor
    public let muted: (ColorPalette) -> NSColor
    public let active: (ColorPalette) -> NSColor
    public let mediaOverlay: (ColorPalette) -> NSColor

    public static let liquidGlass = ChromeIconColors(
        primary: { $0.text },
        secondary: { $0.darkGrayText },
        muted: { $0.text.withAlphaComponent(0.75) },
        active: { $0.text },
        mediaOverlay: { $0.text }
    )

    public static let classic = ChromeIconColors(
        primary: { $0.text },
        secondary: { $0.text },
        muted: { $0.text },
        active: { $0.accentIcon },
        mediaOverlay: { _ in .white }
    )
}

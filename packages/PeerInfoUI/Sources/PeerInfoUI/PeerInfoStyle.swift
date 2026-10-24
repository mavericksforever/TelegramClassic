import Cocoa
import TGUIKit
import ColorPalette

struct PeerInfoStyle: InterfaceStyleVariants {
    enum ActionFill {
        case blended
        case translucentAccent(alpha: CGFloat)
    }

    struct Media {
        enum Selection {
            case lens(inset: CGFloat)
            case underline(height: CGFloat, cornerRadius: CGFloat)
        }

        let topSpacing: CGFloat
        let tabsHeight: CGFloat
        let panelInset: CGFloat
        let tabsFloat: Bool
        let selection: Selection
        let itemInset: CGFloat
        let font: NSFont
        let textColor: (ColorPalette, Bool) -> NSColor
        let selectionColor: (ColorPalette) -> NSColor
        let panelBackground: (ColorPalette) -> NSColor
        let panelBorder: BorderType?
        let searchCornerRadius: CGFloat
        let contentCornerRadius: CGFloat
        let fadesPinnedHeader: Bool
    }

    let headerTopInset: CGFloat
    let headerRowInset: NSEdgeInsets
    let headerFillsRow: Bool
    let revealsBarOnScroll: Bool
    let barBackground: (ColorPalette) -> NSColor
    let barBorder: (ColorPalette) -> NSColor
    let actionFill: ActionFill
    let actionCornerRadius: CGFloat
    let media: Media

    static let liquidGlass = PeerInfoStyle(
        headerTopInset: 20,
        headerRowInset: NSEdgeInsets(left: 8, right: 8, top: 8),
        headerFillsRow: false,
        revealsBarOnScroll: false,
        barBackground: { _ in .clear },
        barBorder: { _ in .clear },
        actionFill: .blended,
        actionCornerRadius: 20,
        media: Media(
            topSpacing: 0,
            tabsHeight: 40,
            panelInset: 12,
            tabsFloat: true,
            selection: .lens(inset: 3),
            itemInset: 16,
            font: .medium(.title),
            textColor: { palette, _ in palette.text },
            selectionColor: { $0.text.withAlphaComponent($0.isDark ? 0.1 : 0.075) },
            panelBackground: { _ in .clear },
            panelBorder: nil,
            searchCornerRadius: 20,
            contentCornerRadius: 20,
            fadesPinnedHeader: true
        )
    )

    static let classic = PeerInfoStyle(
        headerTopInset: InterfaceStyle.classic.navigationBar.height,
        headerRowInset: NSEdgeInsets(left: 20, right: 20),
        headerFillsRow: true,
        revealsBarOnScroll: true,
        barBackground: { $0.background },
        barBorder: { $0.border },
        actionFill: .translucentAccent(alpha: 0.2),
        actionCornerRadius: 10,
        media: Media(
            topSpacing: 20,
            tabsHeight: 40,
            panelInset: 0,
            tabsFloat: false,
            selection: .underline(height: 3, cornerRadius: 2),
            itemInset: 5,
            font: .normal(.title),
            textColor: { palette, selected in selected ? palette.accent : palette.grayText },
            selectionColor: { $0.accent },
            panelBackground: { $0.background },
            panelBorder: [.Bottom],
            searchCornerRadius: 0,
            contentCornerRadius: 0,
            fadesPinnedHeader: false
        )
    )
}

import Cocoa
import TGUIKit
import TelegramTheme

struct InlineAudioPlayerStyle: InterfaceStyleVariants {
    let usesGlass: Bool
    let containerInset: CGFloat
    let cornerRadius: CGFloat
    let collapsedHeight: CGFloat
    let background: (TelegramPresentationTheme) -> NSColor
    let separatorColor: ((TelegramPresentationTheme) -> NSColor)?

    static let liquidGlass = InlineAudioPlayerStyle(
        usesGlass: true,
        containerInset: 12,
        cornerRadius: 20,
        collapsedHeight: 52,
        background: { _ in .clear },
        separatorColor: nil
    )

    static let classic = InlineAudioPlayerStyle(
        usesGlass: false,
        containerInset: 0,
        cornerRadius: 0,
        collapsedHeight: 44,
        background: { $0.colors.background },
        separatorColor: { $0.colors.border }
    )
}

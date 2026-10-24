import Cocoa
import TGUIKit
import TelegramTheme
import LocalAnimations

struct LeftSidebarStyle: InterfaceStyleVariants {
    enum Surface {
        case glass(cornerRadius: CGFloat)
        case column
    }

    enum PressFeedback {
        case scale
        case highlightIcon
    }

    let surface: Surface
    let columnWidth: CGFloat
    let insets: NSEdgeInsets
    let editPressFeedback: PressFeedback
    let titleColor: (TelegramPresentationTheme, Bool) -> NSColor
    let badgeColor: (TelegramPresentationTheme, Bool, Bool) -> NSColor
    let badgeTextColor: (TelegramPresentationTheme, Bool) -> NSColor

    static let liquidGlass = LeftSidebarStyle(
        surface: .glass(cornerRadius: 20),
        columnWidth: 90,
        insets: NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 0),
        editPressFeedback: .scale,
        titleColor: { theme, selected in selected ? theme.colors.accent : theme.colors.text },
        badgeColor: { theme, selected, hasUnmutedUnread in selected || hasUnmutedUnread ? theme.colors.accent : theme.colors.grayIcon },
        badgeTextColor: { theme, _ in theme.colors.underSelectedColor }
    )

    static let classic = LeftSidebarStyle(
        surface: .column,
        columnWidth: 72,
        insets: NSEdgeInsets(),
        editPressFeedback: .highlightIcon,
        titleColor: { _, selected in (selected ? FolderIconState.sidebarActive : FolderIconState.sidebar).color },
        badgeColor: { theme, selected, hasUnmutedUnread in selected ? .white : hasUnmutedUnread ? theme.colors.accentIcon : theme.colors.grayIcon },
        badgeTextColor: { _, selected in selected ? .black : .white }
    )
}

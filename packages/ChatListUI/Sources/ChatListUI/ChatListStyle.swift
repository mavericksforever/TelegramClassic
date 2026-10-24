import Cocoa
import TGUIKit
import TelegramTheme

struct ChatListStyle: InterfaceStyleVariants {

    struct Header {
        let isOpaque: Bool
        let searchBackground: (TelegramPresentationTheme) -> NSColor
        let searchBorderWidth: CGFloat
        let buttonSize: NSSize
        let buttonsShowPressedState: Bool
        let actionsImage: (TelegramPresentationTheme) -> CGImage
    }

    struct FolderTabs {
        let height: CGFloat
        let background: (TelegramPresentationTheme) -> NSColor
        let border: (TelegramPresentationTheme) -> NSColor
        let activeText: (TelegramPresentationTheme) -> NSColor
        let font: NSFont
        let itemInsets: NSEdgeInsets
        let topOverlap: CGFloat
    }

    struct Row {
        let selectionInset: CGFloat
        let selectionCornerRadius: CGFloat
        let compactSelectionHugsAvatar: Bool
    }

    struct ArchiveStrip {
        let inset: CGFloat
        let cornerRadius: CGFloat
        let borderWidth: CGFloat
        let background: (TelegramPresentationTheme) -> NSColor
        let showsIcons: Bool
    }

    struct Downloads {
        let floats: Bool
        let edge: CGFloat
    }

    enum RevealActionShape {
        case captionedCircle
        case filledTile
    }

    struct Reveal {
        let actionShape: RevealActionShape
        let actionInset: CGFloat
    }

    let header: Header
    let folderTabs: FolderTabs
    let row: Row
    let archiveStrip: ArchiveStrip
    let downloads: Downloads
    let reveal: Reveal

    static let liquidGlass = ChatListStyle(
        header: Header(
            isOpaque: false,
            searchBackground: { $0.colors.background },
            searchBorderWidth: 1,
            buttonSize: NSMakeSize(30, 30),
            buttonsShowPressedState: false,
            actionsImage: { $0.icons.chatActions.highlight(color: $0.colors.accent) }
        ),
        folderTabs: FolderTabs(
            height: 30,
            background: { _ in .clear },
            border: { _ in .clear },
            activeText: { $0.colors.text },
            font: .normal(.text),
            itemInsets: NSEdgeInsets(left: 10, right: 10),
            topOverlap: 10
        ),
        row: Row(
            selectionInset: 3,
            selectionCornerRadius: 14,
            compactSelectionHugsAvatar: true
        ),
        archiveStrip: ArchiveStrip(
            inset: 5,
            cornerRadius: 10,
            borderWidth: 1,
            background: { $0.colors.background.withAlphaComponent(0.4) },
            showsIcons: true
        ),
        downloads: Downloads(
            floats: true,
            edge: 12
        ),
        reveal: Reveal(
            actionShape: .captionedCircle,
            actionInset: 6
        )
    )

    static let classic = ChatListStyle(
        header: Header(
            isOpaque: true,
            searchBackground: { $0.search.backgroundColor },
            searchBorderWidth: 0,
            buttonSize: NSMakeSize(40, 30),
            buttonsShowPressedState: true,
            actionsImage: { $0.icons.chatActions }
        ),
        folderTabs: FolderTabs(
            height: 36,
            background: { $0.colors.background },
            border: { $0.colors.border },
            activeText: { $0.colors.accent },
            font: .normal(.title),
            itemInsets: NSEdgeInsets(left: 10, right: 10, bottom: 6),
            topOverlap: 0
        ),
        row: Row(
            selectionInset: 0,
            selectionCornerRadius: 0,
            compactSelectionHugsAvatar: false
        ),
        archiveStrip: ArchiveStrip(
            inset: 0,
            cornerRadius: 0,
            borderWidth: 0,
            background: { $0.colors.grayBackground },
            showsIcons: false
        ),
        downloads: Downloads(
            floats: false,
            edge: 0
        ),
        reveal: Reveal(
            actionShape: .filledTile,
            actionInset: 0
        )
    )
}

import Cocoa
import TGUIKit
import ColorPalette
import TelegramTheme
import TelegramUtils

struct ChatStyle: InterfaceStyleVariants {

    enum StripTransition {
        case fade
        case slide
    }

    enum StripSurface {
        case shared
        case perStrip
    }

    enum SelectionPanel {
        case glassPills
        case textButtons
    }

    struct HeaderIcons {
        let dismiss: (TelegramPresentationTheme) -> CGImage
        let pinnedList: (TelegramPresentationTheme) -> CGImage
        let translate: (TelegramPresentationTheme) -> CGImage
        let translateActions: (TelegramPresentationTheme) -> CGImage
        let botSettings: (TelegramPresentationTheme) -> CGImage
        let storyClose: (TelegramPresentationTheme) -> CGImage
    }

    struct HeaderMetrics {
        let trailing: CGFloat
        let buttonTrailing: CGFloat
        let translateActionTrailing: CGFloat
        let translateActionSize: NSSize
        let adDismissSize: NSSize
        let pendingAvatarsLeading: CGFloat
        let inlineButtonPadding: NSSize
    }

    struct Header {
        let inset: CGFloat
        let floats: Bool
        let buttonsHeight: CGFloat
        let messageHeight: CGFloat
        let stripTransition: StripTransition
        let stripSurface: StripSurface
        let separatorColor: (ColorPalette) -> NSColor
        let actionColor: (ColorPalette) -> NSColor
        let icons: HeaderIcons
        let metrics: HeaderMetrics
    }

    struct SendButton {
        let movesIntoField: Bool
        let size: NSSize
        let icon: (TelegramPresentationTheme, Bool) -> CGImage
        let fill: (ColorPalette) -> NSColor
    }

    struct SearchIcons {
        let next: (TelegramPresentationTheme, Bool) -> CGImage
        let prev: (TelegramPresentationTheme, Bool) -> CGImage
        let calendar: (TelegramPresentationTheme) -> CGImage
        let cancel: (TelegramPresentationTheme) -> CGImage
        let from: (TelegramPresentationTheme) -> CGImage
    }

    struct Keyboard {
        let sideInset: CGFloat
        let contentInset: CGFloat
        let bottomMargin: CGFloat
        let heightPadding: CGFloat
        let cornerRadius: CGFloat
    }

    struct Input {
        let floats: Bool
        let topInset: CGFloat
        let bottomInset: CGFloat
        let edge: CGFloat
        let fieldGap: CGFloat
        let textInset: CGFloat
        let fieldCornerRadius: CGFloat
        let messageGap: CGFloat
        let bubbledMessageGap: CGFloat
        let background: (ColorPalette) -> NSColor
        let placeholderColor: (ColorPalette) -> NSColor
        let send: SendButton
        let keyboard: Keyboard
        let accessoryDismissIcon: (TelegramPresentationTheme) -> CGImage

        var transparentBottomInset: CGFloat {
            return floats ? bottomInset : 0
        }

        var morphsSentTextFromField: Bool {
            return floats
        }
    }

    let showsNavigationBar: Bool
    let fadesContentUnderChrome: Bool
    let serviceUsesGlass: Bool
    let serviceCardCornerRadius: CGFloat
    let navigationButtonShadow: NSShadow?
    let header: Header
    let input: Input
    let searchIcons: SearchIcons
    let selectionPanel: SelectionPanel
    let chromeFollowsChatTheme: Bool

    var serviceGlassEnabled: Bool {
        return serviceUsesGlass && !TelegramUtilsHooks.shared.isLite(.blur)
    }

    func chromeTheme(chatTheme: PresentationTheme?, appTheme: PresentationTheme) -> PresentationTheme {
        return chromeFollowsChatTheme ? chatTheme ?? appTheme : appTheme
    }

    static let liquidGlass = ChatStyle(
        showsNavigationBar: false,
        fadesContentUnderChrome: true,
        serviceUsesGlass: true,
        serviceCardCornerRadius: 20,
        navigationButtonShadow: nil,
        header: Header(
            inset: 12,
            floats: true,
            buttonsHeight: 36,
            messageHeight: 40,
            stripTransition: .fade,
            stripSurface: .shared,
            separatorColor: { $0.text.withAlphaComponent(0.05) },
            actionColor: { $0.text },
            icons: HeaderIcons(
                dismiss: { $0.icons.chat_header_dismiss },
                pinnedList: { $0.icons.chat_header_pinned_list },
                translate: { $0.icons.chat_header_translate },
                translateActions: { $0.icons.chat_header_translate_actions },
                botSettings: { $0.icons.chat_header_bot_settings },
                storyClose: { $0.icons.chat_header_story_close }
            ),
            metrics: HeaderMetrics(
                trailing: 10,
                buttonTrailing: 10,
                translateActionTrailing: 10,
                translateActionSize: .zero,
                adDismissSize: NSMakeSize(36, 36),
                pendingAvatarsLeading: 10,
                inlineButtonPadding: NSMakeSize(6, 8)
            )
        ),
        input: Input(
            floats: true,
            topInset: 0,
            bottomInset: 12,
            edge: 12,
            fieldGap: 10,
            textInset: 12,
            fieldCornerRadius: 20,
            messageGap: 20,
            bubbledMessageGap: 20,
            background: { _ in .clear },
            placeholderColor: { $0.darkGrayText },
            send: SendButton(
                movesIntoField: true,
                size: ChatInputSendButton.fieldSize,
                icon: { theme, isEditing in isEditing ? theme.icons.chat_header_done : theme.icons.send_message_large },
                fill: { $0.accent }
            ),
            keyboard: Keyboard(
                sideInset: 13,
                contentInset: 3,
                bottomMargin: 12,
                heightPadding: 6,
                cornerRadius: 16
            ),
            accessoryDismissIcon: { $0.icons.chat_header_dismiss }
        ),
        searchIcons: SearchIcons(
            next: { theme, enabled in enabled ? theme.icons.chat_search_next : theme.icons.chat_search_next_disabled },
            prev: { theme, enabled in enabled ? theme.icons.chat_search_prev : theme.icons.chat_search_prev_disabled },
            calendar: { $0.icons.chat_search_calendar },
            cancel: { $0.icons.chat_search_cancel },
            from: { $0.icons.chat_search_from }
        ),
        selectionPanel: .glassPills,
        chromeFollowsChatTheme: true
    )

    static let classic = ChatStyle(
        showsNavigationBar: true,
        fadesContentUnderChrome: false,
        serviceUsesGlass: false,
        serviceCardCornerRadius: 10,
        navigationButtonShadow: {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 5
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.1)
            shadow.shadowOffset = NSMakeSize(0, 2)
            return shadow
        }(),
        header: Header(
            inset: 0,
            floats: false,
            buttonsHeight: 44,
            messageHeight: 44,
            stripTransition: .slide,
            stripSurface: .perStrip,
            separatorColor: { $0.border },
            actionColor: { $0.accent },
            icons: HeaderIcons(
                dismiss: { $0.icons.dismissPinned },
                pinnedList: { $0.icons.chat_pinned_list },
                translate: { $0.icons.chat_translate },
                translateActions: { $0.icons.chatActions },
                botSettings: { $0.icons.bot_manager_settings },
                storyClose: { $0.icons.dismissPinned }
            ),
            metrics: HeaderMetrics(
                trailing: 20,
                buttonTrailing: 23,
                translateActionTrailing: 17,
                translateActionSize: NSMakeSize(36, 36),
                adDismissSize: NSMakeSize(30, 30),
                pendingAvatarsLeading: 22,
                inlineButtonPadding: NSMakeSize(16, 8)
            )
        ),
        input: Input(
            floats: false,
            topInset: 5,
            bottomInset: 5,
            edge: 10,
            fieldGap: 0,
            textInset: 10,
            fieldCornerRadius: 0,
            messageGap: 20,
            bubbledMessageGap: 10,
            background: { $0.background },
            placeholderColor: { $0.grayText },
            send: SendButton(
                movesIntoField: false,
                size: NSMakeSize(40, 40),
                icon: { theme, isEditing in isEditing ? theme.icons.chatSaveEditedMessage : theme.icons.chatSendMessage },
                fill: { _ in .clear }
            ),
            keyboard: Keyboard(
                sideInset: 20,
                contentInset: 0,
                bottomMargin: 0,
                heightPadding: 10,
                cornerRadius: 0
            ),
            accessoryDismissIcon: { $0.icons.dismissAccessory }
        ),
        searchIcons: SearchIcons(
            next: { theme, enabled in enabled ? theme.icons.chatSearchDown : theme.icons.chatSearchDownDisabled },
            prev: { theme, enabled in enabled ? theme.icons.chatSearchUp : theme.icons.chatSearchUpDisabled },
            calendar: { $0.icons.chatSearchCalendar },
            cancel: { $0.icons.chatSearchCancel },
            from: { $0.icons.chatSearchFrom }
        ),
        selectionPanel: .textButtons,
        chromeFollowsChatTheme: false
    )
}

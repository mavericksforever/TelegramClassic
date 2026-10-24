import Cocoa
import TGUIKit
import TelegramTheme
import Localization

final class ClassicMessageActionsPanelView: Control, MessageActionsPanel, ChatInputGlassMorphing {

    private let deleteButton = TextButton()
    private let forwardButton = TextButton()
    private let countTitle = TextView()
    private var chatInteraction: ChatInteraction?
    private var currentTheme: TelegramPresentationTheme = theme

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        countTitle.userInteractionEnabled = false
        countTitle.isSelectable = false

        deleteButton.disableActions()
        forwardButton.disableActions()
        deleteButton.scaleOnClick = true
        forwardButton.scaleOnClick = true
        forwardButton.direction = .right
        deleteButton.setAccessibilityLabel(strings().voiceOverMessageContextDelete)
        forwardButton.setAccessibilityLabel(strings().voiceOverMessageContextForward)

        addSubview(deleteButton)
        addSubview(forwardButton)
        addSubview(countTitle)

        updateLocalizationAndTheme(theme: theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isReporting: Bool {
        return chatInteraction?.presentation.reportMode != nil
    }

    override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }

    func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        countTitle.resize(size.width - deleteButton.frame.width - forwardButton.frame.width - 80)
        transition.updateFrame(view: deleteButton, frame: deleteButton.centerFrameY(x: 20))
        transition.updateFrame(view: forwardButton, frame: forwardButton.centerFrameY(x: size.width - forwardButton.frame.width - 20))
        transition.updateFrame(view: countTitle, frame: countTitle.centerFrame())
    }

    func prepare(with chatInteraction: ChatInteraction) {
        if let current = self.chatInteraction {
            current.remove(observer: self)
        }
        self.chatInteraction = chatInteraction
        chatInteraction.add(observer: self)

        forwardButton.set(handler: { [weak chatInteraction] _ in
            chatInteraction?.forwardSelectedMessages()
        }, for: .Click)
        deleteButton.set(handler: { [weak chatInteraction, weak self] _ in
            chatInteraction?.deleteSelectedMessages(morphSource: { [weak self] in self?.deleteButton })
        }, for: .Click)

        notify(with: chatInteraction.presentation, oldValue: chatInteraction.presentation, animated: false)
    }

    func notify(with value: Any, oldValue: Any, animated: Bool) {
        if let value = value as? ChatPresentationInterfaceState, let selectionState = value.selectionState {
            if value.reportMode != nil {
                updateUI(true, selectionState.selectedIds.count > 0, selectionState.selectedIds.count)
            } else {
                updateUI(value.canInvokeBasicActions.delete, value.canInvokeBasicActions.forward, selectionState.selectedIds.count)
            }
        }
    }

    func isEqual(to other: Notifable) -> Bool {
        if let other = other as? ClassicMessageActionsPanelView {
            return self == other
        }
        return false
    }

    private func updateUI(_ canDelete: Bool, _ canForward: Bool, _ count: Int) {
        deleteButton.userInteractionEnabled = canDelete
        forwardButton.userInteractionEnabled = canForward
        applyButtons()

        let text = count == 0 ? strings().messageActionsPanelEmptySelected : strings().messageActionsPanelSelectedCountOther(count)
        let color = (!canForward && !canDelete) || count == 0 ? currentTheme.colors.grayText : currentTheme.colors.text
        countTitle.update(TextViewLayout(.initialize(string: text, color: color, font: .medium(.title)), maximumNumberOfLines: 1, truncationType: .middle))
        needsLayout = true
    }

    private func applyButtons() {
        let theme = currentTheme
        let deleteColor = isReporting ? theme.colors.accent : theme.colors.redUI
        let forwardColor = isReporting ? theme.colors.redUI : theme.colors.accent

        deleteButton.set(text: isReporting ? strings().modalCancel : strings().messageActionsPanelDelete, for: .Normal)
        forwardButton.set(text: isReporting ? strings().modalReport : strings().messageActionsPanelForward, for: .Normal)

        if isReporting {
            deleteButton.removeImage(for: .Normal)
            forwardButton.removeImage(for: .Normal)
        } else {
            deleteButton.set(image: deleteButton.userInteractionEnabled ? theme.icons.chatDeleteMessagesActive : theme.icons.chatDeleteMessagesInactive, for: .Normal)
            forwardButton.set(image: forwardButton.userInteractionEnabled ? theme.icons.chatForwardMessagesActive : theme.icons.chatForwardMessagesInactive, for: .Normal)
        }

        deleteButton.set(color: deleteButton.userInteractionEnabled ? deleteColor : theme.colors.grayIcon, for: .Normal)
        forwardButton.set(color: forwardButton.userInteractionEnabled ? forwardColor : theme.colors.grayIcon, for: .Normal)

        _ = deleteButton.sizeToFit(NSZeroSize, NSMakeSize(0, frame.height))
        _ = forwardButton.sizeToFit(NSZeroSize, NSMakeSize(0, frame.height))
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        let theme = theme as! TelegramPresentationTheme
        currentTheme = theme

        deleteButton.style = ControlStyle(font: .normal(.header), foregroundColor: theme.colors.grayText, backgroundColor: theme.colors.background, highlightColor: theme.colors.redUI)
        forwardButton.style = ControlStyle(font: .normal(.header), foregroundColor: theme.colors.grayText, backgroundColor: theme.colors.background, highlightColor: theme.colors.accentIcon)
        countTitle.set(background: theme.colors.background, for: .Normal)
        backgroundColor = theme.colors.background

        if let chatInteraction {
            notify(with: chatInteraction.presentation, oldValue: chatInteraction.presentation, animated: false)
        } else {
            applyButtons()
        }
    }

    override func viewDidMoveToWindow() {
        if window == nil {
            chatInteraction?.remove(observer: self)
            self.resignFirstResponder()
        }
    }

    func glassMorphSlots(visible: Bool) -> ChatInputGlassSlots? {
        return nil
    }

    func setMorphGlassHidden(_ hidden: Bool) {
    }
}

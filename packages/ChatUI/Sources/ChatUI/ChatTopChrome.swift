import Cocoa
import AVFoundation
import TGUIKit
import Postbox
import TelegramCore
import AvatarUI
import Localization
import TelegramTheme
import TelegramUtils

enum ChatHeaderMenuMode {
    case menu
    case done
}

protocol ChatTopChrome: AnyObject, InteractionContentViewProtocol {
    var backHandler: (() -> Void)? { get set }
    var avatarHandler: (() -> Void)? { get set }
    var avatarAccessibilityActionName: (() -> String?)? { get set }
    var titleHandler: (() -> Void)? { get set }
    var searchHandler: (() -> Void)? { get set }
    var callHandler: (() -> Void)? { get set }
    var doneHandler: (() -> Void)? { get set }
    var menuContextMenu: (() -> ContextMenu?)? { get set }

    var connectionStatus: ConnectionStatus { get set }
    var inputActivities: (PeerId, [(Peer, PeerInputActivity)])? { get set }
    var hasBackButton: Bool { get set }
    var isCloseButton: Bool { get set }
    var hasStories: Bool { get }
    var avatarStoryControl: AvatarStoryControl { get }

    func update(_ peerView: PeerView?, story: PeerExpiringStoryListContext.State?, counters: ChatTitleCounters, animated: Bool)
    func updatePresentation(_ presentation: ChatPresentationInterfaceState, force: Bool)
    func updateSearchButton(hidden: Bool, animated: Bool)
    func setMenuMode(_ mode: ChatHeaderMenuMode)
}

final class NavigationBarChatTopChrome: ChatTopChrome {
    let leftBar: BarView
    let titleBar: ChatTitleBarView
    let rightBar: BarView
    private let menuButton = ImageButton()
    private let doneButton = TextButton()

    var backHandler: (() -> Void)? {
        didSet {
            titleBar.backHandler = backHandler
        }
    }
    var avatarHandler: (() -> Void)? {
        get { return titleBar.avatarHandler }
        set { titleBar.avatarHandler = newValue }
    }
    var avatarAccessibilityActionName: (() -> String?)? {
        get { return titleBar.avatarAccessibilityActionName }
        set { titleBar.avatarAccessibilityActionName = newValue }
    }
    var titleHandler: (() -> Void)? {
        get { return titleBar.titleHandler }
        set { titleBar.titleHandler = newValue }
    }
    var searchHandler: (() -> Void)? {
        get { return titleBar.searchHandler }
        set { titleBar.searchHandler = newValue }
    }
    var callHandler: (() -> Void)? {
        get { return titleBar.callHandler }
        set { titleBar.callHandler = newValue }
    }
    var doneHandler: (() -> Void)?
    var menuContextMenu: (() -> ContextMenu?)?

    var connectionStatus: ConnectionStatus {
        get { return titleBar.connectionStatus }
        set { titleBar.connectionStatus = newValue }
    }
    var inputActivities: (PeerId, [(Peer, PeerInputActivity)])? {
        get { return titleBar.inputActivities }
        set { titleBar.inputActivities = newValue }
    }
    var hasBackButton: Bool {
        get { return titleBar.hasBackButton }
        set { titleBar.hasBackButton = newValue }
    }
    var isCloseButton: Bool = false {
        didSet {
            if oldValue != isCloseButton {
                updateMenuButtonImages()
            }
        }
    }
    var hasStories: Bool {
        return titleBar.hasStories
    }
    var avatarStoryControl: AvatarStoryControl {
        return titleBar.avatarStoryControl
    }

    init(controller: ViewController, chatInteraction: ChatInteraction) {
        self.leftBar = BarView(20, controller: controller)
        self.titleBar = ChatTitleBarView(controller: controller, chatInteraction)
        self.rightBar = BarView(70, controller: controller)

        leftBar.set(handler: { [weak self] _ in
            self?.backHandler?()
        }, for: .Click)

        rightBar.addSubview(menuButton)
        rightBar.addSubview(doneButton)

        menuButton.set(handler: { [weak self] _ in
            if self?.isCloseButton == true {
                self?.backHandler?()
            }
        }, for: .Click)
        menuButton.contextMenu = { [weak self] in
            guard let self, !self.isCloseButton else {
                return nil
            }
            return self.menuContextMenu?()
        }

        doneButton.set(font: .medium(.text), for: .Normal)
        doneButton.set(text: strings().navigationDone, for: .Normal)
        doneButton.set(handler: { [weak self] _ in
            self?.doneHandler?()
        }, for: .Click)
        doneButton.isHidden = true

        updateLocalizationAndTheme()
    }

    func updateLocalizationAndTheme() {
        menuButton.style = navigationButtonStyle
        updateMenuButtonImages()
        menuButton.setFrameSize(70, 50)
        menuButton.center()

        doneButton.style = navigationButtonStyle
        doneButton.set(color: theme.colors.accent, for: .Normal)
        _ = doneButton.sizeToFit()
        doneButton.center()
    }

    private func updateMenuButtonImages() {
        let normal = isCloseButton ? theme.icons.modalClose : theme.icons.chatActions
        let highlight = isCloseButton ? theme.icons.modalClose : theme.icons.chatActionsActive
        menuButton.set(image: normal, for: .Normal)
        menuButton.set(image: highlight, for: .Highlight)
    }

    func update(_ peerView: PeerView?, story: PeerExpiringStoryListContext.State?, counters: ChatTitleCounters, animated: Bool) {
        titleBar.update(peerView, story: story, counters: counters, animated: animated)
    }

    func updatePresentation(_ presentation: ChatPresentationInterfaceState, force: Bool) {
        titleBar.updateStatus(force, presentation: presentation)
    }

    func updateSearchButton(hidden: Bool, animated: Bool) {
        titleBar.updateSearchButton(hidden: hidden, animated: animated)
    }

    func setMenuMode(_ mode: ChatHeaderMenuMode) {
        menuButton.isHidden = mode == .done
        doneButton.isHidden = mode == .menu
    }

    func contentInteractionView(for stableId: AnyHashable, animateIn: Bool) -> NSView? {
        return titleBar.contentInteractionView(for: stableId, animateIn: animateIn)
    }

    func interactionControllerDidFinishAnimation(interactive: Bool, for stableId: AnyHashable) {
        titleBar.interactionControllerDidFinishAnimation(interactive: interactive, for: stableId)
    }

    func addAccesoryOnCopiedView(for stableId: AnyHashable, view: NSView) {
        titleBar.addAccesoryOnCopiedView(for: stableId, view: view)
    }

    func videoTimebase(for stableId: AnyHashable) -> CMTimebase? {
        return titleBar.videoTimebase(for: stableId)
    }

    func applyTimebase(for stableId: AnyHashable, timebase: CMTimebase?) {
        titleBar.applyTimebase(for: stableId, timebase: timebase)
    }
}

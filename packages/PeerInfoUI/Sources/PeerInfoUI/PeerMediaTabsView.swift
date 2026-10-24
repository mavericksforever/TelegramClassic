import Cocoa
import TGUIKit
import TelegramCore
import TelegramMedia
import TelegramTheme
import InlineStickerLayer

final class PeerMediaTabsView: View, HorizontalScrollConsuming {
    struct Tab: Equatable {
        let id: Int64
        let title: String
        let gifts: [ProfileGiftsContext.State.StarGift]
    }

    private static var style: PeerInfoStyle.Media {
        return PeerInfoStyle.current.media
    }
    static var height: CGFloat {
        return style.tabsHeight
    }
    private static var contentInset: CGFloat {
        switch style.selection {
        case let .lens(inset):
            return inset
        case .underline:
            return 0
        }
    }
    private static var selectionCornerRadius: CGFloat {
        switch style.selection {
        case .lens:
            return (height - contentInset * 2) / 2
        case let .underline(_, cornerRadius):
            return cornerRadius
        }
    }
    private static let giftIconSize: CGFloat = 18
    private static let giftIconSpacing: CGFloat = 1
    private static let giftTitleSpacing: CGFloat = 2
    private static let scrollLookahead: CGFloat = 100

    private final class ItemView: View {
        private let textView = TextView()
        private var giftViews: [AnyHashable: InlineStickerView] = [:]
        private var giftOrder: [AnyHashable] = []
        private(set) var contentWidth: CGFloat = 0

        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            textView.userInteractionEnabled = false
            textView.isSelectable = false
            addSubview(textView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(tab: Tab, selected: Bool, account: Account, theme: TelegramPresentationTheme, animated: Bool) {
            let style = PeerMediaTabsView.style
            let layout = TextViewLayout(.initialize(string: tab.title, color: style.textColor(theme.colors, selected), font: style.font), maximumNumberOfLines: 1)
            layout.measure(width: .greatestFiniteMagnitude)
            textView.update(layout)

            var validIds: [AnyHashable] = []
            for (index, gift) in tab.gifts.enumerated() {
                let id: AnyHashable = gift.reference.flatMap { AnyHashable($0) } ?? AnyHashable(index)
                guard let file = PeerMediaTabsView.iconFile(gift) else {
                    continue
                }
                validIds.append(id)
                if giftViews[id] == nil {
                    let size = NSMakeSize(PeerMediaTabsView.giftIconSize, PeerMediaTabsView.giftIconSize)
                    let view = InlineStickerView(account: account, file: file, size: size, playPolicy: .playCount(1))
                    addSubview(view)
                    giftViews[id] = view
                    if animated {
                        view.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
                        view.layer?.animateScaleCenter(from: 0.01, to: 1, duration: 0.2)
                    }
                }
            }
            for (id, view) in giftViews where !validIds.contains(id) {
                giftViews.removeValue(forKey: id)
                if animated {
                    view.layer?.animateScaleCenter(from: 1, to: 0.01, duration: 0.25, removeOnCompletion: false)
                }
                performSubviewRemoval(view, animated: animated, duration: 0.25)
            }
            giftOrder = validIds

            var width = textView.frame.width
            if !validIds.isEmpty {
                width += PeerMediaTabsView.giftIconSpacing + CGFloat(validIds.count) * (PeerMediaTabsView.giftIconSize + PeerMediaTabsView.giftIconSpacing)
            }
            contentWidth = width
            needsLayout = true
        }

        override func layout() {
            super.layout()
            let originX = floorToScreenPixels(backingScaleFactor, (frame.width - contentWidth) / 2)
            textView.setFrameOrigin(NSMakePoint(originX, floorToScreenPixels(backingScaleFactor, (frame.height - textView.frame.height) / 2)))
            var iconX = textView.frame.maxX + PeerMediaTabsView.giftTitleSpacing
            for id in giftOrder {
                if let view = giftViews[id] {
                    view.setFrameOrigin(NSMakePoint(iconX, floorToScreenPixels(backingScaleFactor, (frame.height - view.frame.height) / 2)))
                    iconX += PeerMediaTabsView.giftIconSize + PeerMediaTabsView.giftIconSpacing
                }
            }
        }
    }

    private let glass: LiquidGlassView? = PeerMediaTabsView.style.tabsFloat ? LiquidGlassView(frame: NSZeroRect, cornerRadius: PeerMediaTabsView.height / 2, hasShadow: true, hasBorder: true) : nil
    private let clipView = View()
    private let contentView = View()
    private let selectionView = View()
    private var itemViews: [Int64: ItemView] = [:]

    private(set) var tabs: [Tab] = []
    private(set) var selectedId: Int64?
    private var selectionPosition: CGFloat?
    private var scrollOffset: CGFloat = 0
    private var currentTheme: TelegramPresentationTheme = theme
    private var account: Account?
    private var focusSelectedOnLayout = false

    var didSelect: ((Int64) -> Void)?
    var menuItems: ((Int64, Int) -> [ContextMenuItem])?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.masksToBounds = false
        isHidden = true
        if let glass {
            addSubview(glass)
            clipView.layer?.cornerRadius = (PeerMediaTabsView.height - PeerMediaTabsView.contentInset * 2) / 2
        }
        clipView.layer?.masksToBounds = true
        addSubview(clipView)
        clipView.addSubview(contentView)
        selectionView.isHidden = true
        selectionView.layer?.cornerRadius = PeerMediaTabsView.selectionCornerRadius
        contentView.addSubview(selectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func iconFile(_ gift: ProfileGiftsContext.State.StarGift) -> TelegramMediaFile? {
        switch gift.gift {
        case let .generic(gift):
            return gift.file
        case let .unique(gift):
            for attribute in gift.attributes {
                if case let .model(_, file, _, _) = attribute {
                    return file
                }
            }
            return nil
        }
    }

    func index(of id: Int64) -> Int? {
        return tabs.firstIndex(where: { $0.id == id })
    }

    func contains(_ id: Int64) -> Bool {
        return index(of: id) != nil
    }

    private var itemFrames: [NSRect] {
        let style = PeerMediaTabsView.style
        let widths = tabs.map { (itemViews[$0.id]?.contentWidth ?? 0) + style.itemInset * 2 }
        let gap = style.tabsFloat ? 0 : fillGap(widths)
        var x: CGFloat = gap
        return widths.map { width in
            let frame = NSMakeRect(x, 0, width, PeerMediaTabsView.height - PeerMediaTabsView.contentInset * 2)
            x = frame.maxX + gap
            return frame
        }
    }

    private func fillGap(_ widths: [CGFloat]) -> CGFloat {
        let total = widths.reduce(0, +)
        let available = frame.width - PeerMediaTabsView.contentInset * 2
        guard widths.count > 1, total < available else {
            return 0
        }
        return floor((available - total) / CGFloat(widths.count + 1))
    }

    private var contentWidth: CGFloat {
        return itemFrames.last?.maxX ?? 0
    }

    func size(fitting width: CGFloat) -> NSSize {
        let fittingWidth = PeerMediaTabsView.style.tabsFloat ? min(width, contentWidth + PeerMediaTabsView.contentInset * 2) : width
        return NSMakeSize(fittingWidth, PeerMediaTabsView.height)
    }

    func update(tabs: [Tab], selected: Int64?, account: Account, animated: Bool) {
        let transition: ContainedViewLayoutTransition = animated ? .animated(duration: 0.4, curve: .spring) : .immediate
        let previousIds = Set(self.tabs.map { $0.id })
        let selectionChanged = self.selectedId != selected

        self.tabs = tabs
        self.selectedId = selected
        self.account = account
        self.isHidden = tabs.isEmpty

        let validIds = Set(tabs.map { $0.id })
        for (id, view) in itemViews where !validIds.contains(id) {
            itemViews.removeValue(forKey: id)
            if animated {
                view.layer?.animateScaleCenter(from: 1, to: 0.01, duration: 0.25, removeOnCompletion: false)
            }
            performSubviewRemoval(view, animated: animated, duration: 0.25)
        }
        for tab in tabs {
            let view: ItemView
            if let current = itemViews[tab.id] {
                view = current
            } else {
                view = ItemView(frame: .zero)
                contentView.addSubview(view)
                itemViews[tab.id] = view
            }
            view.update(tab: tab, selected: tab.id == selected, account: account, theme: currentTheme, animated: animated && previousIds.contains(tab.id))
        }

        let frames = itemFrames
        for (tab, itemFrame) in zip(tabs, frames) {
            guard let view = itemViews[tab.id] else {
                continue
            }
            if !previousIds.contains(tab.id) {
                view.frame = itemFrame
                if animated, !previousIds.isEmpty {
                    view.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
                    view.layer?.animateScaleCenter(from: 0.01, to: 1, duration: 0.3)
                }
            } else {
                transition.updateFrame(view: view, frame: itemFrame)
            }
            view.needsLayout = true
        }

        selectionPosition = selected.flatMap { id in tabs.firstIndex(where: { $0.id == id }) }.flatMap { CGFloat($0) }
        if selectionChanged {
            focusSelectedOnLayout = true
        }
    }

    func apply(frame: NSRect, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(view: self, frame: frame)
        updateLayout(size: frame.size, transition: transition)
    }

    func setSelection(position: CGFloat, animated: Bool) {
        if !animated {
            selectionView.layer?.removeAllAnimations()
        }
        selectionPosition = position
        focusSelectedOnLayout = true
        updateLayout(size: frame.size, transition: animated ? .animated(duration: 0.4, curve: .spring) : .immediate)
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        guard let theme = theme as? TelegramPresentationTheme else {
            return
        }
        currentTheme = theme
        if let account {
            update(tabs: tabs, selected: selectedId, account: account, animated: false)
        }
        updateLayout(size: frame.size, transition: .immediate)
    }

    private func selectionFrame(at position: CGFloat, frames: [NSRect]) -> NSRect {
        let clamped = min(max(position, 0), CGFloat(frames.count - 1))
        let lower = Int(clamped.rounded(.down))
        let upper = min(lower + 1, frames.count - 1)
        let progress = clamped - CGFloat(lower)
        let minX = frames[lower].minX + (frames[upper].minX - frames[lower].minX) * progress
        let width = frames[lower].width + (frames[upper].width - frames[lower].width) * progress
        switch PeerMediaTabsView.style.selection {
        case .lens:
            return NSMakeRect(minX, 0, width, frames[lower].height)
        case let .underline(height, _):
            let itemInset = PeerMediaTabsView.style.itemInset
            return NSMakeRect(minX + itemInset, frames[lower].height - height, width - itemInset * 2, height * 2)
        }
    }

    private func clampedScrollOffset(_ offset: CGFloat, visibleWidth: CGFloat) -> CGFloat {
        return max(0, min(offset, contentWidth - visibleWidth))
    }

    private func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        let focusSelected = focusSelectedOnLayout
        focusSelectedOnLayout = false
        selectionView.backgroundColor = PeerMediaTabsView.style.selectionColor(currentTheme.colors)

        if let glass {
            transition.updateFrame(view: glass, frame: size.bounds)
            glass.updateLayout(size: size, transition: transition)
        }

        let inset = PeerMediaTabsView.contentInset
        let clipFrame = NSMakeRect(inset, inset, max(0, size.width - inset * 2), max(0, size.height - inset * 2))
        transition.updateFrame(view: clipView, frame: clipFrame)

        let frames = itemFrames
        if !PeerMediaTabsView.style.tabsFloat {
            for (tab, itemFrame) in zip(tabs, frames) {
                if let view = itemViews[tab.id] {
                    transition.updateFrame(view: view, frame: itemFrame)
                }
            }
        }
        var selection: NSRect?
        if let position = selectionPosition, !frames.isEmpty {
            selection = selectionFrame(at: position, frames: frames)
        }

        var offset = clampedScrollOffset(scrollOffset, visibleWidth: clipFrame.width)
        if focusSelected, let selection {
            let lookahead = PeerMediaTabsView.scrollLookahead
            if offset + clipFrame.width - lookahead < selection.maxX {
                offset = selection.maxX - clipFrame.width + lookahead
            }
            if offset > selection.minX - lookahead {
                offset = selection.minX - lookahead
            }
            offset = clampedScrollOffset(offset, visibleWidth: clipFrame.width)
        }
        scrollOffset = offset
        transition.updateFrame(view: contentView, frame: NSMakeRect(-offset, 0, max(contentWidth, clipFrame.width), clipFrame.height))

        if let selection {
            let selectionTransition: ContainedViewLayoutTransition = selectionView.isHidden ? .immediate : transition
            selectionView.isHidden = false
            selectionTransition.updateFrame(view: selectionView, frame: selection)
        } else {
            selectionView.isHidden = true
        }
    }

    override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }

    private func tabId(at point: NSPoint) -> (id: Int64, index: Int)? {
        let location = contentView.convert(point, from: self)
        for (index, itemFrame) in itemFrames.enumerated() where location.x >= itemFrame.minX && location.x < itemFrame.maxX {
            return (tabs[index].id, index)
        }
        return nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return super.hitTest(point) == nil ? nil : self
    }

    override var mouseDownCanMoveWindow: Bool {
        return false
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            rightMouseDown(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard !event.modifierFlags.contains(.control) else {
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point), let tab = tabId(at: point) {
            didSelect?(tab.id)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let tab = tabId(at: point), let items = menuItems?(tab.id, tab.index), !items.isEmpty else {
            return
        }
        ContextMenu.show(items: items, view: self, event: event)
    }

    func consumesHorizontalScroll(atWindowPoint windowPoint: NSPoint) -> Bool {
        return !isHidden && contentWidth > clipView.frame.width && bounds.contains(convert(windowPoint, from: nil))
    }

    override func scrollWheel(with event: NSEvent) {
        let visibleWidth = clipView.frame.width
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY), contentWidth > visibleWidth {
            let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : event.scrollingDeltaX * 10
            scrollOffset = clampedScrollOffset(scrollOffset - delta, visibleWidth: visibleWidth)
            contentView.setFrameOrigin(NSMakePoint(-scrollOffset, 0))
        } else {
            super.scrollWheel(with: event)
        }
    }
}

import Cocoa

public final class StackedBarView: BarView {

    public static var pillHeight: CGFloat {
        return InterfaceStyle.current.barButton.minSide
    }

    public private(set) var buttons: [ImageButton] = []

    private let glassWrapper: GlassContainerView
    private var ghosts: [ObjectIdentifier: LiquidGlassView] = [:]
    private var validLayout: NSSize?

    public init(controller: ViewController) {
        self.glassWrapper = GlassContainerView(frame: .zero, flipped: true, spacing: 0)
        super.init(controller: controller)
        self.layer?.masksToBounds = false
        self.glassWrapper.glassContent.backgroundColor = .clear
        addSubview(glassWrapper)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }

    private func createButton(image: CGImage? = nil, text: String? = nil, glassForceAppearance: LiquidGlassAppearance? = nil, handler: (() -> Void)? = nil) -> ImageButton {
        let metrics = InterfaceStyle.current.barButton
        let btn: ImageButton
        if let text = text {
            let textBtn = TextButton()
            textBtn.autoSizeToFit = false
            textBtn.set(text: text, for: .Normal)
            applyTextStyle(textBtn)
            btn = textBtn
        } else {
            btn = ImageButton()
        }
        if let image = image {
            btn.set(image: image, for: .Normal)
        }
        btn.scaleOnClick = metrics.usesGlass
        btn.disableActions()
        btn.animates = false
        btn.autohighlight = false
        btn.shadow = nil
        btn.layer?.masksToBounds = false

        if let handler {
            btn.set(handler: { _ in handler() }, for: .Click)
        }
        addSubview(btn)
        if metrics.usesGlass {
            let ghost = LiquidGlassView(frame: .zero, cornerRadius: metrics.minSide / 2, hasShadow: true, hasBorder: true, forceAppearance: glassForceAppearance)
            glassWrapper.addGhost(ghost)
            ghosts[ObjectIdentifier(btn)] = ghost
            btn.interactiveGlassView = ghost
            btn.additionalGlassEffectView = ghost
        }
        return btn
    }

    private func applyTextStyle(_ button: TextButton) {
        if InterfaceStyle.current.barButton.followsBarPresentation, let controller {
            button.set(font: controller.barPresentation.font, for: .Normal)
            button.set(color: controller.barPresentation.foregroundColor, for: .Normal)
            button.set(background: controller.barPresentation.backgroundColor, for: .Normal)
        } else {
            button.set(font: .normal(.title), for: .Normal)
            button.set(color: presentation.colors.text, for: .Normal)
            button.set(background: .clear, for: .Normal)
        }
    }

    private func slotWidth(for button: ImageButton) -> CGFloat {
        let metrics = InterfaceStyle.current.barButton
        if let textButton = button as? TextButton, !textButton.isEmpty {
            return button.frame.width + metrics.textMargin
        }
        return max(button.frame.width, metrics.imageMinWidth)
    }

    @discardableResult
    public func addButton(image: CGImage? = nil, text: String? = nil, glassForceAppearance: LiquidGlassAppearance? = nil, handler: (() -> Void)? = nil) -> ImageButton {
        let btn = createButton(image: image, text: text, glassForceAppearance: glassForceAppearance, handler: handler)
        buttons.append(btn)
        validLayout = nil
        return btn
    }

    @discardableResult
    public func insertButton(at index: Int, image: CGImage? = nil, text: String? = nil, glassForceAppearance: LiquidGlassAppearance? = nil, handler: (() -> Void)? = nil) -> ImageButton {
        let btn = createButton(image: image, text: text, glassForceAppearance: glassForceAppearance, handler: handler)
        let clamped = max(0, min(index, buttons.count))
        buttons.insert(btn, at: clamped)
        validLayout = nil
        return btn
    }

    public func removeButton(_ btn: ImageButton) {
        btn.removeFromSuperview()
        buttons.removeAll(where: { $0 === btn })
        if let ghost = ghosts.removeValue(forKey: ObjectIdentifier(btn)) {
            glassWrapper.removeGhost(ghost)
        }
        validLayout = nil
    }

    public func set(hidden: Bool, for button: ImageButton) {
        guard button.isHidden != hidden else {
            return
        }
        button.isHidden = hidden
        validLayout = nil
        superview?.needsLayout = true
    }

    /// Animate the button's icon opacity, and toggle the corresponding glass
    /// ghost's visibility instantly. The merged glass surface lives in the
    /// container's SDF compositor and animating opacity on the wrapper layer
    /// doesn't reach it; toggling `isHidden` is what makes the compositor
    /// release / reinstate the surface.
    public func change(opacity: CGFloat, for button: ImageButton, animated: Bool = true) {
        button.change(opacity: opacity, animated: animated)
        ghosts[ObjectIdentifier(button)]?.isHidden = opacity <= 0
    }

    private var visibleButtons: [ImageButton] {
        return buttons.filter { !$0.isHidden }
    }

    override var isFitted: Bool {
        return true
    }

    public override func fit(to maxWidth: CGFloat, transition: ContainedViewLayoutTransition = .immediate) -> CGFloat {
        let metrics = InterfaceStyle.current.barButton
        validLayout = .zero
        let visible = visibleButtons
        for btn in visible {
            if let textBtn = btn as? TextButton, !textBtn.isEmpty {
                _ = textBtn.sizeToFit(NSMakeSize(metrics.textPadding, 0), NSMakeSize(maxWidth, metrics.minSide), thatFit: false, transition: transition)
            } else {
                btn.sizeToFit(.zero, NSMakeSize(metrics.minSide, metrics.minSide), thatFit: true, transition: transition)
            }
        }
        return contentWidth(of: visible)
    }

    private func contentWidth(of buttons: [ImageButton]) -> CGFloat {
        let slots = buttons.reduce(CGFloat(0)) { $0 + slotWidth(for: $1) }
        return slots + CGFloat(max(0, buttons.count - 1)) * InterfaceStyle.current.barButton.spacing
    }

    public override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        for btn in buttons {
            if let textBtn = btn as? TextButton {
                applyTextStyle(textBtn)
            }
        }
        // Forward to each ghost so its forceAppearance.didSet rebuilds the
        // inner NSGlassEffectView at the new dark/light boundary.
        for (_, ghost) in ghosts {
            ghost.updateLocalizationAndTheme(theme: theme)
        }
    }

    public override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }

    public override func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        // Bail when size matches the cache. The synchronous `layout()` pass
        // that runs after an animator-driven resize enters here with
        // `.immediate`; without this guard, transition.updateFrame on each
        // ghost / button would clobber the in-flight CABasicAnimations.
        if size == validLayout { return }
        validLayout = size

        let visible = visibleButtons
        let spacing = InterfaceStyle.current.barButton.spacing

        transition.updateFrame(view: glassWrapper, frame: size.bounds)
        glassWrapper.updateLayout(size: size, transition: transition)

        var x = size.width - contentWidth(of: visible)
        for btn in visible {
            let slot = slotWidth(for: btn)
            let btnSize = btn.frame.size
            let origin = NSMakePoint(x + floorToScreenPixels(backingScaleFactor, (slot - btnSize.width) / 2), floorToScreenPixels(backingScaleFactor, (size.height - btnSize.height) / 2))
            let btnFrame = NSRect(origin: origin, size: btnSize)
            transition.updateFrame(view: btn, frame: btnFrame)
            btn.updateLayout(size: btnSize, transition: transition)
            if let ghost = ghosts[ObjectIdentifier(btn)] {
                // Track the button's target opacity so a faded-out button
                // doesn't leave its glass blob behind when layout re-runs.
                let buttonOpacity = btn.layer?.opacity ?? 1
                ghost.isHidden = buttonOpacity <= 0.01
                glassWrapper.setGhostFrame(ghost, frame: btnFrame, transition: transition)
            }
            x += slot + spacing
        }

        // Hide ghosts whose buttons are hidden.
        for btn in buttons where btn.isHidden {
            ghosts[ObjectIdentifier(btn)]?.isHidden = true
        }
    }
}

import Cocoa

open class BackNavigationBar: TextButtonBarView {

    public init(_ controller:ViewController, glassForceAppearance: LiquidGlassAppearance? = nil) {
        let backSettings = controller.backSettings()
        super.init(controller: controller, text: BackNavigationBar.title(backSettings), style: controller.barPresentation, glassForceAppearance: glassForceAppearance)

        if let image = backSettings.1 {
            set(image: image, for: .Normal)
        }
        set(handler: { [weak self] _ in
            self?.controller?.executeReturn()
        }, for: .Click)

        requestUpdate()
    }

    override var isFitted: Bool {
        return super.isFitted
    }

    public func requestUpdate() {
        guard let controller = self.controller else {
            return
        }
        let backSettings = controller.backSettings()
        set(text: BackNavigationBar.title(backSettings), for: .Normal)
        if let image = backSettings.1 {
             set(image: image, for: .Normal)
        } else {
            removeImage(for: .Normal)
        }
        style = controller.barPresentation
        needsLayout = true
    }

    private static func title(_ backSettings: (String, CGImage?)) -> String {
        return InterfaceStyle.current.barButton.backShowsTitle ? backSettings.0 : ""
    }

    open override func fit(to maxWidth: CGFloat, transition: ContainedViewLayoutTransition = .immediate) -> CGFloat {
        let metrics = InterfaceStyle.current.barButton
        let maxSize = button.isEmpty ? NSMakeSize(metrics.minSide, metrics.minSide) : NSMakeSize(maxWidth, metrics.minSide)
        button.sizeToFit(.zero, maxSize, thatFit: button.isEmpty, transition: transition)
        return metrics.backLeadingMargin + button.frame.width + metrics.backTrailingMargin
    }

    open override func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        super.updateLayout(size: size, transition: transition)
        transition.updateFrame(view: button, frame: button.centerFrameY(x: InterfaceStyle.current.barButton.backLeadingMargin))
        button.updateLayout(size: button.frame.size, transition: transition)
    }

    open override func layout() {
        super.layout()
        self.updateLayout(size: frame.size, transition: .immediate)
    }
    
    deinit {
        var bp:Int = 0
        bp += 1
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required public init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}

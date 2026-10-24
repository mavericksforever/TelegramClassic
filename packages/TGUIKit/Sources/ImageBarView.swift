import Cocoa

public class ImageBarView: BarView {

    public var button: ImageButton = ImageButton()

    public func set(image: CGImage, highlightImage: CGImage? = nil) {
        button.set(image: image, for: .Normal)
        if let highlight = highlightImage {
            button.set(image: highlight, for: .Highlight)
        }
    }

    public init(controller: ViewController, _ image: CGImage, _ highlight: CGImage? = nil) {
        super.init(controller: controller)

        let metrics = InterfaceStyle.current.barButton
        button.disableActions()
        button.animates = false
        button.autohighlight = false
        if metrics.usesGlass {
            button.scaleOnClick = true
            button.layer?.cornerRadius = metrics.minSide / 2
            button.layer?.masksToBounds = true
            button.setGlassEffect()
        }

        addSubview(button)
        self.layer?.masksToBounds = false
        set(image: image, highlightImage: highlight)
    }

    required public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(button)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func fit(to maxWidth: CGFloat, transition: ContainedViewLayoutTransition = .immediate) -> CGFloat {
        let metrics = InterfaceStyle.current.barButton
        button.sizeToFit(.zero, NSMakeSize(metrics.minSide, metrics.minSide), thatFit: true, transition: transition)
        return max(button.frame.width, metrics.imageMinWidth)
    }

    open override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }

    open override func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        let buttonSize = button.frame.size
        let x = floorToScreenPixels(backingScaleFactor, (size.width - buttonSize.width) / 2)
        let y = floorToScreenPixels(backingScaleFactor, (size.height - buttonSize.height) / 2)
        transition.updateFrame(view: button, frame: NSMakeRect(x, y, buttonSize.width, buttonSize.height))
        button.updateLayout(size: buttonSize, transition: transition)
    }
    
    public override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        button.updateLocalizationAndTheme(theme: theme)
    }
}

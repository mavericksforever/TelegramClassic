import Cocoa
import TGUIKit
import TelegramTheme
import TelegramIconsTheme
import ImageCanvasUI
import Localization

open class MediaPreviewEditControl: View {
    private let crop = ImageButton()
    private let paint = ImageButton()
    private let delete = ImageButton()
    private var surfaceView: NSView?
    public override init() {
        super.init(frame: NSMakeRect(0, 0, 90, 30))
        let surface: View
        switch MediaPreviewEditStyle.current.surface {
        case let .glass(cornerRadius):
            surface = LiquidGlassView(frame: NSZeroRect, cornerRadius: cornerRadius, hasShadow: true, hasBorder: true)
        case let .capsule(color):
            surface = View()
            surface.backgroundColor = color
            surface.layer?.cornerRadius = frame.height / 2
        }
        addSubview(surface)
        surfaceView = surface
        layer?.masksToBounds = false

        addSubview(crop)
        addSubview(paint)
        addSubview(delete)
        crop.autohighlight = false
        paint.autohighlight = false
        delete.autohighlight = false
        crop.scaleOnClick = true
        paint.scaleOnClick = true
        delete.scaleOnClick = true
        crop.set(image: theme.icons.editor_crop, for: .Normal)
        paint.set(image: theme.icons.editor_draw, for: .Normal)
        delete.set(image: theme.icons.editor_delete, for: .Normal)
        _ = crop.sizeToFit(NSZeroSize, NSMakeSize(27, frame.height), thatFit: true)
        _ = delete.sizeToFit(NSZeroSize, NSMakeSize(27, frame.height), thatFit: true)
        _ = paint.sizeToFit(NSZeroSize, NSMakeSize(27, frame.height), thatFit: true)
        crop.setAccessibilityLabel(strings().voiceOverCommonCrop)
        paint.setAccessibilityLabel(strings().voiceOverCommonDraw)
        delete.setAccessibilityLabel(strings().voiceOverCommonDelete)

    }
    
    public func set(edit:@escaping()->Void, paint: @escaping()->Void, delete:@escaping()->Void, editedData: EditedImageData?) {
        self.crop.removeAllHandlers()
        self.delete.removeAllHandlers()
        self.paint.removeAllHandlers()

        self.crop.set(handler: { _ in
            edit()
        }, for: .Click)
        
        self.paint.set(handler: { _ in
            paint()
        }, for: .Click)
        
        self.delete.set(handler: { _ in
            delete()
        }, for: .Click)
    }
    
    public var canEdit: Bool = true {
        didSet {
            updateEditing()
        }
    }

    public var isVideo: Bool = false {
        didSet {
            guard isVideo != oldValue else {
                return
            }
            crop.set(image: isVideo ? EditVideoIcons.edit.precomposed(ChromeIconColors.current.mediaOverlay(theme.colors)) : theme.icons.editor_crop, for: .Normal)
            crop.setAccessibilityLabel(isVideo ? strings().voiceOverCommonEdit : strings().voiceOverCommonCrop)
            updateEditing()
        }
    }

    private func updateEditing() {
        crop.isHidden = !canEdit
        paint.isHidden = !canEdit || isVideo
        self.setFrameSize(canEdit ? (isVideo ? 60 : 90) : 30, frame.height)
        needsLayout = true
    }

    public var canDelete: Bool = true {
        didSet {
            delete.isHidden = !canDelete
        }
    }
    
    public var isInteractiveMedia: Bool = true {
        didSet {
            surfaceView?.isHidden = !isInteractiveMedia
            delete.set(image: isInteractiveMedia ? theme.icons.editor_delete : theme.icons.previewSenderDeleteFile, for: .Normal)
        }
    }
    
    public override func layout() {
        super.layout()
        surfaceView?.frame = bounds
        if canEdit {
            crop.centerY(x: 3)
            if isVideo {
                delete.centerY(x: crop.frame.maxX)
            } else {
                paint.centerY(x: crop.frame.maxX)
                delete.centerY(x: paint.frame.maxX)
            }
        } else {
            delete.center()
        }
    }
    
    public override var isHidden: Bool {
        didSet {
            var bp:Int = 0
            bp += 1
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }
}

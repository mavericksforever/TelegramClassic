import Cocoa
import ColorPalette

public enum InterfaceStyleKind {
    case liquidGlass
    case classic

    public static let current: InterfaceStyleKind = {
        if #available(macOS 26.0, *) {
            return .liquidGlass
        }
        return .classic
    }()
}

public protocol InterfaceStyleVariants {
    static var liquidGlass: Self { get }
    static var classic: Self { get }
}

public extension InterfaceStyleVariants {
    static var current: Self {
        switch InterfaceStyleKind.current {
        case .liquidGlass:
            return liquidGlass
        case .classic:
            return classic
        }
    }
}

public struct InterfaceStyle: InterfaceStyleVariants {

    public struct NavigationBar {
        public let height: CGFloat
        public let contentTopInset: CGFloat
        public let overlaysContent: Bool
        public let drawsChrome: Bool
        public let itemsInset: CGFloat
        public let centerSpansFullWidth: Bool
        public let buttonStyle: (ColorPalette) -> ControlStyle
    }

    public struct BarButton {
        public let usesGlass: Bool
        public let minSide: CGFloat
        public let textPadding: CGFloat
        public let textMargin: CGFloat
        public let imageMinWidth: CGFloat
        public let spacing: CGFloat
        public let backShowsTitle: Bool
        public let backLeadingMargin: CGFloat
        public let backTrailingMargin: CGFloat
        public let followsBarPresentation: Bool
    }

    public struct Controls {
        public let pressScale: CGFloat
        public let stretchesOnPress: Bool
        public let drawsUntintedGlass: Bool
        public let glassMaxCornerRadius: CGFloat
    }

    public struct Window {
        public let extendsContentUnderTitlebar: Bool
        public let showsConnectingStatusInTitlebar: Bool
        public let transparentCompactTitlebar: Bool
    }

    public struct Split {
        public let paneInset: CGFloat
        public let paneCornerRadius: CGFloat
        public let floatingPanes: Bool
        public let minimizedPaneWidth: CGFloat
        public let drawsDivider: Bool
    }

    public struct Modal {
        public let cornerRadius: CGFloat
        public let opaqueChrome: Bool
    }

    public struct ScaleSpring {
        public let from: CGFloat
        public let duration: Double
        public let bounce: Bool
    }

    public struct Menu {
        public enum Appearance {
            case bubble
            case spring(ScaleSpring)
            case fade
        }

        public let cornerRadius: CGFloat
        public let rowCornerRadius: CGFloat
        public let clickAppearance: Appearance
        public let submenuAppearance: Appearance
        public let topPanelSpring: ScaleSpring
    }

    public struct Segment {
        public enum Selection {
            case insetFromItem(CGFloat)
            case aroundText(verticalPadding: CGFloat)
        }

        public let usesGlass: Bool
        public let itemInset: CGFloat
        public let itemSpacing: CGFloat
        public let selection: Selection
        public let textColor: (ColorPalette, Bool) -> NSColor
        public let selectionColor: (ColorPalette) -> NSColor
    }

    public let navigationBar: NavigationBar
    public let barButton: BarButton
    public let controls: Controls
    public let window: Window
    public let split: Split
    public let modal: Modal
    public let menu: Menu
    public let segment: Segment
    public let popoverCornerRadius: CGFloat
    public let fadesNavigationTransitions: Bool
    public let controllerCornerRadius: CGFloat
    public let searchFieldCornerRadius: CGFloat
    public let listCardCornerRadius: CGFloat
    public let drawsFlatSurfaces: Bool

    public static let liquidGlass = InterfaceStyle(
        navigationBar: NavigationBar(
            height: 64,
            contentTopInset: 50,
            overlaysContent: true,
            drawsChrome: false,
            itemsInset: 12,
            centerSpansFullWidth: true,
            buttonStyle: { palette in
                ControlStyle(font: .medium(.title), foregroundColor: palette.text, backgroundColor: .clear, highlightColor: palette.text.withAlphaComponent(0.9))
            }
        ),
        barButton: BarButton(
            usesGlass: true,
            minSide: 40,
            textPadding: 20,
            textMargin: 0,
            imageMinWidth: 40,
            spacing: 10,
            backShowsTitle: false,
            backLeadingMargin: 0,
            backTrailingMargin: 0,
            followsBarPresentation: false
        ),
        controls: Controls(
            pressScale: 1.03,
            stretchesOnPress: true,
            drawsUntintedGlass: true,
            glassMaxCornerRadius: 999
        ),
        window: Window(
            extendsContentUnderTitlebar: true,
            showsConnectingStatusInTitlebar: false,
            transparentCompactTitlebar: false
        ),
        split: Split(
            paneInset: 8,
            paneCornerRadius: 20,
            floatingPanes: true,
            minimizedPaneWidth: 90,
            drawsDivider: false
        ),
        modal: Modal(
            cornerRadius: 20,
            opaqueChrome: false
        ),
        menu: Menu(
            cornerRadius: 18,
            rowCornerRadius: 14,
            clickAppearance: .bubble,
            submenuAppearance: .bubble,
            topPanelSpring: ScaleSpring(from: 0.2, duration: 0.28, bounce: true)
        ),
        segment: Segment(
            usesGlass: true,
            itemInset: 12,
            itemSpacing: -8,
            selection: .insetFromItem(3),
            textColor: { palette, _ in palette.text },
            selectionColor: { $0.text.withAlphaComponent($0.isDark ? 0.1 : 0.075) }
        ),
        popoverCornerRadius: 18,
        fadesNavigationTransitions: true,
        controllerCornerRadius: 20,
        searchFieldCornerRadius: 15,
        listCardCornerRadius: 20,
        drawsFlatSurfaces: false
    )

    public static let classic = InterfaceStyle(
        navigationBar: NavigationBar(
            height: 50,
            contentTopInset: 0,
            overlaysContent: false,
            drawsChrome: true,
            itemsInset: 0,
            centerSpansFullWidth: false,
            buttonStyle: { palette in
                ControlStyle(font: .medium(.title), foregroundColor: palette.accent, backgroundColor: palette.background, highlightColor: palette.accent)
            }
        ),
        barButton: BarButton(
            usesGlass: false,
            minSide: 0,
            textPadding: 0,
            textMargin: 30,
            imageMinWidth: 60,
            spacing: 0,
            backShowsTitle: true,
            backLeadingMargin: 16,
            backTrailingMargin: 4,
            followsBarPresentation: true
        ),
        controls: Controls(
            pressScale: 0.97,
            stretchesOnPress: false,
            drawsUntintedGlass: false,
            glassMaxCornerRadius: 10
        ),
        window: Window(
            extendsContentUnderTitlebar: false,
            showsConnectingStatusInTitlebar: true,
            transparentCompactTitlebar: true
        ),
        split: Split(
            paneInset: 0,
            paneCornerRadius: 0,
            floatingPanes: false,
            minimizedPaneWidth: 70,
            drawsDivider: true
        ),
        modal: Modal(
            cornerRadius: 10,
            opaqueChrome: true
        ),
        menu: Menu(
            cornerRadius: 10,
            rowCornerRadius: .cornerRadius,
            clickAppearance: .spring(ScaleSpring(from: 0.1, duration: 0.2, bounce: false)),
            submenuAppearance: .fade,
            topPanelSpring: ScaleSpring(from: 0.1, duration: 0.2, bounce: false)
        ),
        segment: Segment(
            usesGlass: false,
            itemInset: 10,
            itemSpacing: 4,
            selection: .aroundText(verticalPadding: 4.5),
            textColor: { palette, isSelected in isSelected ? palette.darkGrayText : palette.grayIcon },
            selectionColor: { $0.grayText.withAlphaComponent(0.2) }
        ),
        popoverCornerRadius: 10,
        fadesNavigationTransitions: false,
        controllerCornerRadius: 0,
        searchFieldCornerRadius: 6,
        listCardCornerRadius: 10,
        drawsFlatSurfaces: true
    )
}

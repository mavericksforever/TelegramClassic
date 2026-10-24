import Cocoa
import TGUIKit

struct EntertainmentStyle: InterfaceStyleVariants {
    enum SidebarSurface {
        case glass(cornerRadius: CGFloat)
        case column
    }

    let usesGlass: Bool
    let tabsAreaHeight: CGFloat
    let tabsOverlayContent: Bool
    let sidebarGrowsWindow: Bool
    let sidebarSurface: SidebarSurface
    let sidebarInsets: NSEdgeInsets

    var sidebarCornerRadius: CGFloat {
        switch sidebarSurface {
        case let .glass(cornerRadius):
            return cornerRadius
        case .column:
            return 0
        }
    }

    var sectionBottomInset: CGFloat {
        return tabsOverlayContent ? 0 : tabsAreaHeight
    }

    var contentBottomInset: CGFloat {
        return tabsOverlayContent ? tabsAreaHeight : 0
    }

    static let liquidGlass = EntertainmentStyle(
        usesGlass: true,
        tabsAreaHeight: 56,
        tabsOverlayContent: true,
        sidebarGrowsWindow: true,
        sidebarSurface: .glass(cornerRadius: 20),
        sidebarInsets: NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 8)
    )

    static let classic = EntertainmentStyle(
        usesGlass: false,
        tabsAreaHeight: 50,
        tabsOverlayContent: false,
        sidebarGrowsWindow: false,
        sidebarSurface: .column,
        sidebarInsets: NSEdgeInsets()
    )
}

import Cocoa
import TGUIKit

struct CallHeaderStyle: InterfaceStyleVariants {
    let inset: CGFloat
    let barOverhang: CGFloat
    let roundsBar: Bool

    static let liquidGlass = CallHeaderStyle(
        inset: 12,
        barOverhang: 2,
        roundsBar: true
    )

    static let classic = CallHeaderStyle(
        inset: 0,
        barOverhang: 0,
        roundsBar: false
    )
}

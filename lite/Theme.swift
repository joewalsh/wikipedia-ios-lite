import UIKit

extension UIColor {
    convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    convenience init(_ hexString: String, alpha: CGFloat = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        guard hex.count == 6, Scanner(string: hex).scanHexInt32(&int) && int != UINT32_MAX else {
            assertionFailure("Unexpected issue scanning hex string: \(hexString)")
            self.init(white: 0, alpha: alpha)
            return
        }
        self.init(Int(int), alpha: alpha)
    }

    convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }

    static let base100 = UIColor(0xFFFFFF)
    static let parchment = UIColor(0xF8F1E3)
    static let thermosphere = UIColor(0x2E3136)
}

class Colors {
    let paperBackground: UIColor

    init(paperBackground: UIColor) {
        self.paperBackground = paperBackground
    }

    static let light = Colors(paperBackground: .base100)
    static let sepia = Colors(paperBackground: .parchment)
    static let dark = Colors(paperBackground: .thermosphere)
    static let black = Colors(paperBackground: .black)
}

public class Theme {
    let colors: Colors
    let kind: Kind

    enum Kind: Int {
        case light
        case sepia
        case dark
        case black

        var name: String {
            switch self {
            case .light:
                return "DEFAULT"
            case .sepia:
                return "SEPIA"
            case .dark:
                return "DARK"
            case .black:
                return "BLACK"
            }
        }

        var colors: Colors {
            switch self {
            case .light:
                return Colors.light
            case .sepia:
                return Colors.sepia
            case .dark:
                return Colors.dark
            case .black:
                return Colors.black
            }
        }
    }

    init(kind: Kind) {
        self.kind = kind
        self.colors = kind.colors
    }

    static let light = Theme(kind: .light)
    static let sepia = Theme(kind: .sepia)
    static let dark = Theme(kind: .dark)
    static let black = Theme(kind: .black)
}

public protocol Themeable: AnyObject {
    func apply(theme: Theme)
}

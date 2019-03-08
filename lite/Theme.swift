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

    fileprivate static let base100 = UIColor(0xFFFFFF)
    fileprivate static let parchment = UIColor(0xF8F1E3)
    fileprivate static let thermosphere = UIColor(0x2E3136)
    fileprivate static let mesosphere = UIColor(0x43464A)
    fileprivate static let base10 = UIColor(0x222222)
    fileprivate static let base90 = UIColor(0xF8F9FA)
    fileprivate static let blue50 = UIColor(0x3366CC)
    fileprivate static let stratosphere = UIColor(0x6699FF)
}

class Colors {
    let paperBackground: UIColor
    let chromeBackground: UIColor
    let chromeText: UIColor
    let link: UIColor

    init(paperBackground: UIColor, chromeBackground: UIColor, chromeText: UIColor, link: UIColor) {
        self.paperBackground = paperBackground
        self.chromeBackground = chromeBackground
        self.chromeText = chromeText
        self.link = link
    }

    static let light = Colors(paperBackground: .base100, chromeBackground: .base100, chromeText: .base10, link: .blue50)
    static let sepia = Colors(paperBackground: .parchment, chromeBackground: .parchment, chromeText: .base10, link: .blue50)
    static let dark = Colors(paperBackground: .thermosphere, chromeBackground: .mesosphere, chromeText: .base90, link: .stratosphere)
    static let black = Colors(paperBackground: .black, chromeBackground: .base10, chromeText: .base90, link: .stratosphere)
}

public class Theme {
    let kind: Kind
    let colors: Colors
    let dimImages: Bool
    let imageOpacity: CGFloat
    let isDark: Bool

    enum Kind: Int, CaseIterable {
        case light
        case sepia
        case dark
        case black

        var name: String {
            switch self {
            case .light:
                return "Default"
            case .sepia:
                return "Sepia"
            case .dark:
                return "Dark"
            case .black:
                return "Black"
            }
        }

        var jsName: String {
            return name.uppercased()
        }

        var colors: Colors {
            switch self {
            case .light:
                return .light
            case .sepia:
                return .sepia
            case .dark:
                return .dark
            case .black:
                return .black
            }
        }

        var isDark: Bool {
            return self == .dark || self == .black
        }
    }

    init(kind: Kind, dimImages: Bool = false) {
        assert(kind.isDark == false ? dimImages == false : true, "Only dark themes support image dimming")
        self.kind = kind
        self.colors = kind.colors
        self.isDark = kind.isDark
        self.dimImages = dimImages
        self.imageOpacity = dimImages ? 0.46 : 1
    }

    static let standard = Theme.light
    static let light = Theme(kind: .light)
    static let sepia = Theme(kind: .sepia)
    static let dark = Theme(kind: .dark)
    static let black = Theme(kind: .black)
}

public protocol Themeable: AnyObject {
    func apply(theme: Theme)
}

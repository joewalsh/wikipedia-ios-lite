import UIKit

protocol Nibbed {
    static func instantiate() -> Self
}

extension Nibbed where Self: UIView {
    static func instantiate() -> Self {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?.first as! Self
    }
}

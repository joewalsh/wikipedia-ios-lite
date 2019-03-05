import Foundation

extension UserDefaults {
    enum Key: String {
        case collapseTables
    }

    @objc dynamic var collapseTables: Bool {
        get {
            return bool(forKey: Key.collapseTables.rawValue)
        }
        set {
            set(newValue, forKey: Key.collapseTables.rawValue)
        }
    }
}

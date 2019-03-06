import Foundation

extension UserDefaults {
    enum Key: String {
        case collapseTables
        case theme
    }

    enum Theme: Int {
        case `default`
        case sepia
        case dark
        case black

        var name: String {
            switch self {
            case .default:
                return "DEFAULT"
            case .sepia:
                return "SEPIA"
            case .dark:
                return "DARK"
            case .black:
                return "BLACK"
            }
        }
    }

    @objc dynamic var collapseTables: Bool {
        get {
            return bool(forKey: Key.collapseTables.rawValue)
        }
        set {
            set(newValue, forKey: Key.collapseTables.rawValue)
        }
    }

    var theme: Theme? {
        get {
            guard
                let theme = Theme(rawValue: integer(forKey: Key.theme.rawValue))
            else {
                return nil
            }
            return theme
        }
        set {
            set(newValue?.rawValue, forKey: Key.theme.rawValue)
            notify(with: UserDefaults.didChangeThemeNotification, object: theme)
        }
    }

    private func notify(with notificationName: Notification.Name, object: Any?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: notificationName, object: object)
        }
    }
}

extension UserDefaults {
    static let didChangeThemeNotification = Notification.Name(rawValue: "didChangeThemeNotification")
}

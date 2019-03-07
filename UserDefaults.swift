import Foundation

extension UserDefaults {
    enum Key: String {
        case collapseTables
        case theme
    }

    @objc dynamic var collapseTables: Bool {
        get {
            return bool(forKey: Key.collapseTables.rawValue)
        }
        set {
            set(newValue, forKey: Key.collapseTables.rawValue)
        }
    }

    var theme: Theme.Kind {
        get {
            guard
                let theme = Theme.Kind(rawValue: integer(forKey: Key.theme.rawValue))
            else {
                return Theme.standard.kind
            }
            return theme
        }
        set {
            set(newValue.rawValue, forKey: Key.theme.rawValue)
            notify(with: UserDefaults.didChangeThemeNotification, object: Theme(kind: theme))
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

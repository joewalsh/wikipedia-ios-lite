import Foundation

extension UserDefaults {
    enum Key: String {
        case collapseTables
        case theme
        case dimImages
    }

    @objc dynamic var collapseTables: Bool {
        get {
            return bool(forKey: Key.collapseTables.rawValue)
        }
        set {
            set(newValue, forKey: Key.collapseTables.rawValue)
        }
    }

    var theme: (kind: Theme.Kind, dimImages: Bool) {
        get {
            guard
                let themeKind = Theme.Kind(rawValue: integer(forKey: Key.theme.rawValue))
            else {
                return (Theme.standard.kind, false)
            }
            return (themeKind, bool(forKey: Key.dimImages.rawValue))
        }
        set {
            set(newValue.kind.rawValue, forKey: Key.theme.rawValue)
            set(newValue.dimImages, forKey: Key.dimImages.rawValue)
            let newTheme = Theme(kind: theme.kind, dimImages: theme.dimImages)
            notify(with: UserDefaults.didChangeThemeNotification, object: newTheme)
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

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

    var themeKind: Theme.Kind {
        get {
            guard
                let kind = Theme.Kind(rawValue: integer(forKey: Key.theme.rawValue))
            else {
                return Theme.standard.kind
            }
            return kind
        }
        set {
            set(newValue.rawValue, forKey: Key.theme.rawValue)
            notify(with: UserDefaults.didChangeThemeNotification, object: theme)
        }
    }

    var theme: Theme {
        get {
            return Theme(kind: themeKind, dimImages: dimImages)
        }
        set {
            themeKind = newValue.kind
            dimImages = newValue.dimImages
        }
    }

    var dimImages: Bool {
        get {
            return bool(forKey: Key.dimImages.rawValue)
        }
        set {
            set(newValue, forKey: Key.dimImages.rawValue)
            notify(with: UserDefaults.didUpdateDimImages, object: newValue)
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
    static let didUpdateDimImages = Notification.Name(rawValue: "didUpdateDimImages")
}

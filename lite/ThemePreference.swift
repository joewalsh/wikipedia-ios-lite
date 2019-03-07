import UIKit

class ThemePreference: UIView, Nibbed {
    @IBOutlet private var themeButtons: [UIButton] = []
    private var selectedButton: UIButton?
    let defaults = UserDefaults.standard

    override func didMoveToWindow() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeWasUpdated(_:)), name: UserDefaults.didChangeThemeNotification, object: nil)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        guard newWindow == nil else {
            return
        }
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        assert(Theme.Kind.allCases.count == themeButtons.count)
        for (kind, button) in zip(Theme.Kind.allCases, themeButtons) {
            button.tag = kind.rawValue
            let isCurrentTheme = kind.rawValue == defaults.theme.rawValue
            if isCurrentTheme {
                button.isSelected = true
                selectedButton = button
            }
            button.setTitle(kind.name, for: .normal)
        }
    }

    @objc private func themeWasUpdated(_ notification: NSNotification) {
        guard let theme = notification.object as? Theme else {
            return
        }
        selectedButton?.isSelected = false
        selectedButton = themeButtons.first(where: { $0.tag == theme.kind.rawValue })
        selectedButton?.isSelected = true
    }

    @IBAction private func updateThemePreference(_ sender: UIButton) {
        guard let theme = Theme.Kind(rawValue: sender.tag) else {
            return
        }
        defaults.theme = theme
    }
}

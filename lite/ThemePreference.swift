import UIKit

class ThemePreference: UIView, Nibbed {
    @IBOutlet private var themeButtons: [UIButton] = []
    private var selectedButton: UIButton?
    let defaults = UserDefaults.standard

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

    @IBAction private func updateThemePreference(_ sender: UIButton) {
        guard let theme = Theme.Kind(rawValue: sender.tag) else {
            return
        }
        selectedButton?.isSelected = false
        sender.isSelected = true
        selectedButton = sender
        defaults.theme = theme
    }
}

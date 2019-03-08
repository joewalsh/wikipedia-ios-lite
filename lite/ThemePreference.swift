import UIKit

class ThemePreference: UIView, Nibbed {
    @IBOutlet private var themeButtons: [UIButton] = []
    @IBOutlet private weak var dimImagesLabel: UILabel!
    @IBOutlet private weak var dimImagesSwitch: UISwitch!
    private var activeButton: UIButton? {
        didSet {
            oldValue?.isSelected = false
            activeButton?.isSelected = true
        }
    }
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
        let themeKind = defaults.themeKind
        for (kind, button) in zip(Theme.Kind.allCases, themeButtons) {
            button.tag = kind.rawValue
            let isCurrentTheme = button.tag == themeKind.rawValue
            if isCurrentTheme {
                activeButton = button
                dimImagesSwitch.isEnabled = themeKind.isDark
                dimImagesSwitch.isOn = defaults.dimImages
            }
            button.setTitle(kind.name, for: .normal)
        }
    }

    @objc private func themeWasUpdated(_ notification: NSNotification) {
        guard let theme = notification.object as? Theme else {
            return
        }
        activeButton = themeButtons.first(where: { $0.tag == theme.kind.rawValue })
        dimImagesSwitch.isOn = theme.dimImages
        dimImagesSwitch.isEnabled = theme.isDark
    }

    @IBAction private func updateTheme(_ sender: UIButton) {
        guard let themeKind = Theme.Kind(rawValue: sender.tag) else {
            return
        }
        defaults.dimImages = themeKind.isDark ? dimImagesSwitch.isOn : false
        defaults.themeKind = themeKind
    }

    @IBAction private func updateThemWithImageDimming(_ sender: UISwitch) {
        defaults.dimImages = sender.isOn
    }
}

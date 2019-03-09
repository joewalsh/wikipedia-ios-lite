import UIKit
import WebKit

private protocol Item {
    var title: String? { get }
}

class ExploreTableViewController: UITableViewController {
    private let reuseIdentifier = "👻"

    var configuration: Configuration!
    var schemeHandler: SchemeHandler!
    var cacheController: ArticleCacheController!
    var theme = Theme.standard

    var collapseTablesPreferenceObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(articleCacheWasUpdated(_:)), name: ArticleCacheController.didUpdateCacheNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeWasUpdated(_:)), name: UserDefaults.didChangeThemeNotification, object: nil)

        collapseTablesPreferenceObservation = UserDefaults.standard.observe(\.collapseTables, options: [.new]) { defaults, change in
            self.tableView.reloadData()
        }
        apply(theme: theme)
    }

    deinit {
        collapseTablesPreferenceObservation?.invalidate()
        collapseTablesPreferenceObservation = nil
    }

    @objc private func articleCacheWasUpdated(_ notification: Notification) {
        tableView.reloadData()
    }

    @objc private func themeWasUpdated(_ notification: Notification) {
        guard let theme = notification.object as? Theme else {
            return
        }
        apply(theme: theme)
    }

    private struct Article: Item {
        let title: String?
        let url: URL

        init(title: String) {
            self.title = title
            let urlString = "app://en.wikipedia.org/wiki/\(title)"
            self.url = URL(string: urlString)!
        }
    }

    private struct Preference: Item {
        let title: String?
        let titleColor: UIColor
        let accessoryType: UITableViewCell.AccessoryType
        let onSelection: () -> Void
    }

    private struct Custom: Item {
        let title: String?
        let customView: UIView
    }

    enum SectionType: Int {
        case article
        case preferences
    }

    private struct Section {
        let title: String?
        let items: [Item]
    }

    private lazy var articleSection: Section = {
        let articles = [
            Article(title: "Dog"),
            Article(title: "Wolf"),
            Article(title: "Cat"),
            Article(title: "Panda"),
            Article(title: "Unicorn"),
            Article(title: "Barack_Obama")
        ]
        return Section(title: "Explore", items: articles)
    }()

    private var preferencesSection: Section {
        let preferences: [Item] = [
            Preference(
                title: "Clear cache",
                titleColor: UIColor.red,
                accessoryType: .none,
                onSelection: { self.cacheController.clearAll() }),
            Preference(
                title: "Collapse tables",
                titleColor: UIColor.black,
                accessoryType: UserDefaults.standard.collapseTables ? .checkmark : .none,
                onSelection: { UserDefaults.standard.collapseTables = !UserDefaults.standard.collapseTables }),
            Custom(
                title: nil,
                customView: ThemePreference.instantiate())
            ]
        return Section(title: "Preferences", items: preferences)
    }

    private var sections: [Section] {
        var sections = [Section]()
        sections.insert(articleSection, at: SectionType.article.rawValue)
        sections.insert(preferencesSection, at: SectionType.preferences.rawValue)
        return sections
    }

    private func item(at indexPath: IndexPath) -> Item? {
        guard sections.indices.contains(indexPath.section) else {
            return nil
        }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.row) else {
            return nil
        }
        return section.items[indexPath.row]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = sections[section]
        return section.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let item = item(at: indexPath) else {
            assertionFailure("No item at indexPath: \(indexPath)")
            return cell
        }
        switch item {
        case let article as Article:
            cell.textLabel?.text = article.title
            let saveButton = UIButton()
            let isCached = cacheController.isCached(article.url)
            let imageName = isCached ? "save-filled" : "save"
            saveButton.setImage(UIImage(named: imageName), for: .normal)
            saveButton.imageView?.contentMode = .scaleAspectFit
            saveButton.tag = indexPath.row
            saveButton.addTarget(self, action: #selector(toggleArticleSavedState), for: .touchUpInside)
            saveButton.sizeToFit()
            cell.accessoryView = saveButton
            cell.accessibilityLabel = "readArticle"
        case let preference as Preference:
            cell.textLabel?.text = preference.title
            cell.textLabel?.textColor = preference.titleColor
            cell.accessoryType = preference.accessoryType
        case let custom as Custom:
            cell.selectionStyle = .none
            addSubview(custom.customView, to: cell)
        default:
            assertionFailure("Unhandled type: \(item)")
            break
        }
        cell.backgroundColor = theme.colors.paperBackground
        cell.textLabel?.textColor = theme.colors.chromeText
        return cell
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cell.contentView.subviews.isEmpty else {
            return
        }
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
    }

    private func addSubview(_ subview: UIView, to cell: UITableViewCell) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let contentView = cell.contentView
        contentView.addSubview(subview)
        let leading = subview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: tableView.separatorInset.left)
        let trailing = contentView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: tableView.separatorInset.left)
        let centerY = subview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        NSLayoutConstraint.activate([leading, trailing, centerY])
    }

    @objc private func toggleArticleSavedState(_ sender: UIButton) {
        let articleSection = sections[SectionType.article.rawValue]
        guard
            let article = articleSection.items[sender.tag] as? Article
        else {
            return
        }
        cacheController.toggleCache(for: article.url)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            assertionFailure("No item at indexPath: \(indexPath)")
            return
        }
        switch item {
        case let article as Article:
            showArticle(article, withTheme: theme)
        case let preference as Preference:
            preference.onSelection()
        case is Custom:
            break
        default:
            assertionFailure("Unhandled type: \(item)")
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Article presentation

    private func showArticle(_ article: Article, withTheme theme: Theme) {
        let webViewController = self.webViewController(forArticle: article, theme: theme)
        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.apply(theme: theme)
        present(navigationController, animated: true)
    }

    private func addThemePreferencePanel(to navigationController: UINavigationController) {
        let navigationBar = navigationController.navigationBar
        let themePreference = ThemePreference.instantiate()
        themePreference.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(themePreference)
        let centerX = themePreference.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor)
        NSLayoutConstraint.activate([centerX])
    }

    private func webViewController(forArticle article: Article, theme: Theme) -> WebViewController {
        let articleMobileHTMLURL = configuration.mobileAppsServicesArticleResourceURLForArticle(with: article.url, scheme: schemeHandler.scheme, resource: .mobileHTML)!
        let webViewController = WebViewController(url: articleMobileHTMLURL, configuration: webViewConfiguration, theme: theme)
        return webViewController
    }

    private var webViewConfiguration: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        return configuration
    }
}

extension ExploreTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        self.theme = theme
        view.backgroundColor = theme.colors.baseBackground
        tabBarController?.apply(theme: theme)
        tableView.reloadData()
    }
}

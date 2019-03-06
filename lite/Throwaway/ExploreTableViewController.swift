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

    var collapseTablesPreferenceObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(articleCacheWasUpdated(_:)), name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil)

        collapseTablesPreferenceObservation = UserDefaults.standard.observe(\.collapseTables, options: [.new]) { defaults, change in
            self.tableView.reloadSections([SectionType.preferences.rawValue], with: .automatic)
        }
    }

    deinit {
        collapseTablesPreferenceObservation?.invalidate()
        collapseTablesPreferenceObservation = nil
    }

    @objc private func articleCacheWasUpdated(_ notification: Notification) {
        tableView.reloadData()
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

    private struct CustomPreference: Item {
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
            Article(title: "Unicorn")
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
            CustomPreference(
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
        case let preference as Preference:
            cell.textLabel?.text = preference.title
            cell.textLabel?.textColor = preference.titleColor
            cell.accessoryType = preference.accessoryType
        case let customPreference as CustomPreference:
            addSubview(customPreference.customView, to: cell)
        default:
            assertionFailure("Unhandled type: \(item)")
            break
        }
        return cell
    }

    private func addSubview(_ subview: UIView, to cell: UITableViewCell) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let contentView = cell.contentView
        contentView.addSubview(subview)
        let leading = subview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: tableView.separatorInset.left)
        let centerY = subview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        NSLayoutConstraint.activate([leading, centerY])
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
            let webViewConfiguration = WKWebViewConfiguration()
            let contentController = WKUserContentController()
            contentController.addUserScript(CollapseTablesUserScript(collapseTables: UserDefaults.standard.collapseTables))
            contentController.addUserScript(ThemeUserScript())
            webViewConfiguration.userContentController = contentController
            webViewConfiguration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
            let articleMobileHTMLURL = configuration.mobileAppsServicesArticleResourceURLForArticle(with: article.url, scheme: schemeHandler.scheme, resource: .mobileHTML)!
            let webViewController = WebViewController(url: articleMobileHTMLURL, configuration: webViewConfiguration)

            let navigationController = UINavigationController(rootViewController: webViewController)
            present(navigationController, animated: true)
        case let preference as Preference:
            preference.onSelection()
        default:
            assertionFailure("Unhandled type: \(item)")
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

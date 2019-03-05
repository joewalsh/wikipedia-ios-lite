import UIKit
import WebKit

class ExploreTableViewController: UITableViewController {
    private let reuseIdentifier = "👻"

    var configuration: Configuration!
    var schemeHandler: SchemeHandler!
    var cacheController: ArticleCacheController!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(articleCacheWasUpdated(_:)), name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil)
    }

    @objc private func articleCacheWasUpdated(_ notification: Notification) {
        tableView.reloadData()
    }

    private struct Article {
        let title: String
        let url: URL

        init(title: String) {
            self.title = title
            let urlString = "app://en.wikipedia.org/wiki/\(title)"
            self.url = URL(string: urlString)!
        }
    }
        
    private lazy var articles: [Article] = {
        return [
            Article(title: "Dog"),
            Article(title: "Wolf"),
            Article(title: "Cat"),
            Article(title: "Panda"),
            Article(title: "Unicorn")
        ]
    }()

    private func article(at indexPath: IndexPath) -> Article? {
        guard articles.indices.contains(indexPath.row) else {
            return nil
        }
        return articles[indexPath.row]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        if let article = self.article(at: indexPath) {
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
        } else {
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "Clear cache 🔥"
            cell.textLabel?.textColor = UIColor.white
            cell.backgroundColor = UIColor.red
        }
        return cell
    }

    @objc private func toggleArticleSavedState(_ sender: UIButton) {
        let articleURL = articles[sender.tag].url
        cacheController.toggleCache(for: articleURL)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let articleURL = article(at: indexPath)?.url {
            let webViewConfiguration = WKWebViewConfiguration()
            webViewConfiguration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
            let articleMobileHTMLURL = configuration.mobileAppsServicesArticleResourceURLForArticle(with: articleURL, scheme: schemeHandler.scheme, resource: .mobileHTML)!
            let webViewController = WebViewController(url: articleMobileHTMLURL, configuration: webViewConfiguration)

            let navigationController = UINavigationController(rootViewController: webViewController)
            present(navigationController, animated: true)
        } else {
            cacheController.clearAll()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

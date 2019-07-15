import UIKit
import WebKit

final class SearchViewController: UIViewController {
    var theme = Theme.standard

    private lazy var resultsController = SearchResultsTableViewController()
    private lazy var searchController = UISearchController(searchResultsController: resultsController)

    private let searchResultsFetcher: SearchResultsFetcher
    private let configuration: Configuration
    private let webViewConfiguration: WKWebViewConfiguration

    init(session: Session, configuration: Configuration, webViewConfiguration: WKWebViewConfiguration) {
        searchResultsFetcher = SearchResultsFetcher(session: session, configuration: configuration)
        self.configuration = configuration
        self.webViewConfiguration = webViewConfiguration
        super.init(nibName: nil, bundle: nil)
        resultsController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true

        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true

        searchController.searchBar.placeholder = "Search English Wikipedia"
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController

        apply(theme: theme)
    }
}

extension SearchViewController: SearchResultsTableViewControllerDelegate {
    func didSelect(searchResult page: Page) {
        guard let title = page.title?.replacingOccurrences(of: " ", with: "_") else {
            return
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "en.wikipedia.org"
        components.path = "/wiki/\(title)"
        guard
            let articleURL = components.url,
            let mobileHTMLURL = configuration.mobileAppsServicesPageResourceURLForArticle(with: title, baseURL: articleURL, resource: .mobileHTML)
        else {
            return
        }
        let webViewController = WebViewController(articleTitle: title, url: mobileHTMLURL, configuration: webViewConfiguration, theme: theme)
        webViewController.title = page.title
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            self.searchResultsFetcher.results(for: searchText) { result in
                switch result {
                case .success(let pages):
                    DispatchQueue.main.async {
                        self.resultsController.pages = pages
                    }
                default:
                    break
                }
            }
        }
    }
}

extension SearchViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        self.theme = theme
        view.backgroundColor = theme.colors.paperBackground
        searchController.view.backgroundColor = view.backgroundColor
    }
}

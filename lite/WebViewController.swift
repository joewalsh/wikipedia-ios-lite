import UIKit
import WebKit

class WebViewController: UIViewController {
    let configuration: WKWebViewConfiguration
    let url: URL
    weak var navigationDelegate: WKNavigationDelegate?
    var theme = Theme.standard

    required init(url: URL, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), theme: Theme) {
        self.url = url
        self.configuration = configuration
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
        self.navigationDelegate = self
        configuration.userContentController = contentController
        NotificationCenter.default.addObserver(self, selector: #selector(themeWasUpdated(_:)), name: UserDefaults.didChangeThemeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dimImagesPreferenceWasUpdated(_:)), name: UserDefaults.didUpdateDimImages, object: nil)
    }

    private lazy var contentController: WKUserContentController = {
        let contentController = WKUserContentController()

        let themeUserScript = ThemeUserScript(theme: theme) {
            self.webView.isHidden = false
        }
        let tablesUserScript = TablesUserScript(collapse: UserDefaults.standard.collapseTables)
        contentController.addAndHandle(themeUserScript)
        contentController.addAndHandle(tablesUserScript)

        return contentController
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isHidden = true
        webView.navigationDelegate = navigationDelegate
        return webView
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("WebViewController didAppear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addConstrainedSubview(webView)

        let closeButton = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissAnimated))
        closeButton.accessibilityIdentifier = "close"
        navigationItem.rightBarButtonItem = closeButton
        navigationController?.isToolbarHidden = false

        let themePreference = ThemePreference.instantiate()
        themePreference.sizeToFit()
        setToolbarItems([UIBarButtonItem(customView: themePreference)], animated: true)

        let request = URLRequest(url: url, permanentlyPersistedCachePolicy: .ignorePermanentlyPersistedCacheData)
        webView.load(request)

        apply(theme: theme)
    }

    @objc private func dismissAnimated() {
        dismiss(animated: true)
    }

    @objc private func themeWasUpdated(_ notification: Notification) {
        guard let theme = notification.object as? Theme else {
            return
        }
        apply(theme: theme)
    }

    @objc private func dimImagesPreferenceWasUpdated(_ notification: Notification) {
        guard let dim = notification.object as? Bool else {
            return
        }
        webView.dimImages(dim)
    }

    private var loadRetryCount = 0
    private let maxLoadRetryCount = 3
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        #warning("Handle edit, reference links")
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        guard url.host?.hasSuffix("wikipedia.org") ?? false else {
            decisionHandler(.allow)
            return
        }

        let pathComponents = url.pathComponents
        guard pathComponents.count > 1, pathComponents[1] == "wiki" else {
            decisionHandler(.allow)
            return
        }

        guard let scheme = url.scheme else {
            decisionHandler(.allow)
            return
        }

        guard let revisedURL = Configuration.current.mobileAppsServicesArticleResourceURLForArticle(with: url, scheme: scheme, resource: .mobileHTML) else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        let webViewController = WebViewController(url: revisedURL, configuration: configuration, theme: theme)
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let requestError = RequestError.from(code: (error as NSError).code) else {
            showAlert(forError: error)
            return
        }
        switch requestError {
        case .timeout where loadRetryCount == maxLoadRetryCount:
            showAlert(forError: error)
            loadRetryCount = 0
        case .timeout:
            loadRetryCount += 1
            let request = URLRequest(url: url, permanentlyPersistedCachePolicy: .usePermanentlyPersistedCacheData)
            webView.load(request)
        default:
            break
        }
    }

    private func showAlert(forError error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let gotIt = UIAlertAction(title: "Got it", style: .default) { _ in
            self.dismissAnimated()
        }
        alert.addAction(gotIt)
        present(alert, animated: true)
    }
}

extension WebViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        navigationController?.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        webView.backgroundColor = theme.colors.paperBackground
        webView.scrollView.backgroundColor = theme.colors.paperBackground

        webView.apply(theme: theme)
    }
}

private extension WKWebView {
    func apply(theme: Theme) {
        evaluateJavaScript(ThemeUserScript.source(with: theme))
    }

    func dimImages(_ dim: Bool) {
        let source = "window.wmf.dimImages(\(dim.description))"
        evaluateJavaScript(source)
    }
}

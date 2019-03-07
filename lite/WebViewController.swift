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
        NotificationCenter.default.addObserver(self, selector: #selector(themeWasUpdated(_:)), name: UserDefaults.didChangeThemeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = navigationDelegate
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addConstrainedSubview(webView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissAnimated))
        let request = URLRequest(url: url)
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
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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

        guard let adjustedURL = Configuration.current.mobileAppsServicesArticleResourceURLForArticle(with: url, scheme: scheme, resource: .mobileHTML) else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        let webViewController = WebViewController(url: adjustedURL, configuration: configuration, theme: theme)
        navigationController?.pushViewController(webViewController, animated: true)
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
}

import UIKit
import WebKit

class WebViewController: UIViewController {
    let configuration: WKWebViewConfiguration
    let url: URL
    weak var navigationDelegate: WKNavigationDelegate?
    
    required init(url: URL, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.url = url
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.navigationDelegate = self
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
        let request = URLRequest(url: url)
        webView.load(request)
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

        guard let adjustedURL = Configuration.current.mobileAppsServicesArticleURLForArticle(with: url, scheme: scheme) else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        let webViewController = WebViewController(url: adjustedURL, configuration: configuration, fetcher: fetcher)
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

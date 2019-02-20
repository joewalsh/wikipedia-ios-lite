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
        guard pathComponents.count > 1, pathComponents[1] == "wiki", let title = pathComponents.last?.trimmingCharacters(in: Configuration.slashCharacterSet) else {
            decisionHandler(.allow)
            return
        }

        guard var adjustedComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            decisionHandler(.allow)
            return
        }

        adjustedComponents.path = ["", "api", "rest_v1", "page", "mobile-html", title].joined(separator: "/")

        guard let adjustedURL = adjustedComponents.url else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        var adjustedRequest = navigationAction.request
        adjustedRequest.url = adjustedURL
        let webViewController = WebViewController.init(url: adjustedURL, configuration: configuration)
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

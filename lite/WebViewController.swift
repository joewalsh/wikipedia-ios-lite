import UIKit
import WebKit

class WebViewController: UIViewController {
    let configuration: WKWebViewConfiguration
    let url: URL
    weak var navigationDelegate: WKNavigationDelegate?
    
    required init(url: URL, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), navigationDelegate: WKNavigationDelegate?) {
        self.url = url
        self.configuration = configuration
        self.navigationDelegate = navigationDelegate
        super.init(nibName: nil, bundle: nil)
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

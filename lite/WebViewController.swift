import UIKit
import WebKit

class WebViewController: UIViewController {
    let session: Session
    let schemeHandler: SchemeHandler
    let url: URL
    weak var navigationDelegate: WKNavigationDelegate?
    
    required init(session: Session, url: URL, navigationDelegate: WKNavigationDelegate?) {
        self.session = session
        self.schemeHandler = SchemeHandler(scheme: "app", session: session)
        self.url = url
        self.navigationDelegate = navigationDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = navigationDelegate
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addConstrainedSubview(webView)
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = schemeHandler.scheme
        guard let schemeURL = components.url else {
            return
        }
        
        let request = URLRequest(url: schemeURL)
        webView.load(request)
    }

}

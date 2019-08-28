import UIKit
import WebKit

class WebViewController: UIViewController {
    private let articleTitle: String
    private let articleURL: URL
    private let articleFragment: String?
    private let articleCacheController: ArticleCacheController

    private let configuration: Configuration

    private let webViewConfiguration: WKWebViewConfiguration

    weak var navigationDelegate: WKNavigationDelegate?

    private var theme = Theme.standard

    private var readMoreURLs = [String: URL]()
    
    private var loadStart: CFAbsoluteTime?
    private var loadEnd: CFAbsoluteTime?
    
    private lazy var mobileHTMLURL: URL? = {
        //return configuration.mobileAppsServicesMobileHTMLPreviewURL(with: articleURL)
        return configuration.mobileAppsServicesPageResourceURLForArticle(with: articleURL, scheme: "app", resource: .mobileHTML)
    }()

    required init(articleTitle: String, articleURL: URL, articleFragment: String? = nil, articleCacheController: ArticleCacheController, configuration: Configuration, webViewConfiguration: WKWebViewConfiguration) {
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        self.articleFragment = articleFragment
        self.articleCacheController = articleCacheController

        self.configuration = configuration

        self.webViewConfiguration = webViewConfiguration

        super.init(nibName: nil, bundle: nil)

        self.navigationDelegate = self

        webViewConfiguration.userContentController = contentController

        NotificationCenter.default.addObserver(self, selector: #selector(themeWasUpdated(_:)), name: UserDefaults.didChangeThemeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dimImagesWasUpdated(_:)), name: UserDefaults.didUpdateDimImages, object: nil)

        readMoreURLs.reserveCapacity(3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        for userScript in contentController.userScripts {
            guard let messageHandlerName = (userScript as? NamedScriptMessageHandler)?.messageHandlerName else {
                continue
            }
            contentController.removeScriptMessageHandler(forName: messageHandlerName)
        }
        contentController.removeAllUserScripts()
    }

    // TODO: This could be extracted into a WKUserContentController subclass.
    // It would have to delegate back to this VC so that it can 1) evaluateJavaScript 2) push other VCs.
    private lazy var contentController: WKUserContentController = {
        let contentController = WKUserContentController()
        let pageSetupUserScript = PageSetupUserScript(theme: UserDefaults.standard.theme, dimImages: UserDefaults.standard.dimImages, expandTables: UserDefaults.standard.expandTables) { [unowned self] in
            if let articleFragment = self.articleFragment {
                self.webView.evaluateJavaScript(ScrollJavaScript.rectY(for: articleFragment)) { result, error in
                    guard
                        error == nil,
                        let result = result as? [String: Any],
                        let rectY = result["rectY"] as? CGFloat
                    else {
                        return
                    }
                    let point = CGPoint(x: self.webView.scrollView.contentOffset.x, y: rectY + floor(self.webView.scrollView.contentOffset.y))
                    UIView.animate(withDuration: 0, animations: {
                        self.webView.scrollView.setContentOffset(point, animated: false)
                    }, completion: { _ in
                        self.webView.isHidden = false
                    })
                }
            } else {
                self.webView.isHidden = false
            }
            self.markLoadEnd()
        }
        let footerSetupUserScript = FooterSetupUserScript(articleTitle: articleTitle)
        let interactionSetupUserScript = InteractionSetupUserScript { [unowned self] interaction in
            switch interaction.action {
            case .readMoreTitlesRetrieved:
                guard let titles = interaction.data?["titles"] as? [String] else {
                    return
                }
                for title in titles {
                    if let articleURL = self.articleURL.replacingPageTitle(self.articleTitle, with: title) {
                        self.readMoreURLs[title] = articleURL
                        self.webView.evaluateJavaScript(FooterJavaScript.updateReadMoreSaveButton(for: title, saved: self.articleCacheController.isCached(articleURL)))
                    }
                }
            case .linkClicked:
                guard let href = interaction.data?["href"] as? String else {
                    assertionFailure("Unhandled link data")
                    return
                }
                guard let firstIndexOfForwardSlash = href.firstIndex(of: "/") else {
                    assertionFailure("Unhandled link type")
                    return
                }
                let distance = href.distance(from: href.startIndex, to: firstIndexOfForwardSlash)
                if distance == 0 { // external?
                    print()
                } else if String(href[href.startIndex..<firstIndexOfForwardSlash]) == "." { // internal?
                    guard let scheme = self.articleURL.scheme else {
                        assertionFailure("Missing scheme")
                        return
                    }
                    let titleWithOptionalFragment = String(href[href.index(firstIndexOfForwardSlash, offsetBy: 1)...])
                    let title: String
                    let fragment: String?
                    if let indexOfLastHash = titleWithOptionalFragment.lastIndex(of: "#") {
                        title = String(titleWithOptionalFragment[titleWithOptionalFragment.startIndex..<indexOfLastHash])
                        fragment = String(titleWithOptionalFragment[titleWithOptionalFragment.index(indexOfLastHash, offsetBy: 1)...])
                    } else {
                        title = titleWithOptionalFragment
                        fragment = nil
                    }
                    guard let linkedArticleURL = self.articleURL.replacingPageTitle(self.articleTitle, with: title) else {
                        return
                    }
                    let webViewController = WebViewController(articleTitle: title, articleURL: linkedArticleURL, articleCacheController: self.articleCacheController, configuration: self.configuration, webViewConfiguration: self.webViewConfiguration)
                    self.navigationController?.pushViewController(webViewController, animated: true)
                }
            case .saveOtherPage:
                guard let title = interaction.data?["title"] as? String else {
                    assertionFailure("Missing title")
                    return
                }
                guard let articleURL = self.readMoreURLs[title] ?? self.articleURL.replacingPageTitle(self.articleTitle, with: title) else {
                    return
                }
                let isCached = self.articleCacheController.isCached(articleURL)
                self.articleCacheController.toggleCache(!isCached, for: articleURL)
                self.webView.evaluateJavaScript(FooterJavaScript.updateReadMoreSaveButton(for: title, saved: !isCached))
            default:
                let alert = UIAlertController(title: "Interaction", message: interaction.action.rawValue, preferredStyle: .alert)
                let gotIt = UIAlertAction(title: "Got it", style: .default)
                alert.addAction(gotIt)
                self.present(alert, animated: true)
            }
        }
        contentController.addAndHandle(pageSetupUserScript)
        contentController.addAndHandle(footerSetupUserScript)
        contentController.addAndHandle(interactionSetupUserScript)
        return contentController
    }()
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.isHidden = true
        webView.navigationDelegate = navigationDelegate
        return webView
    }()
    

    func preferredVariant(for articleURL: URL) -> String? {
        let code = articleURL.host?.split(separator: ".").first
        if code == "sr" {
            return "sr-el"
        } else if code == "zh" {
            return "zh-hant"
        } else {
            return nil
        }
    }
    private func markLoadStart() {
        loadStart = CFAbsoluteTimeGetCurrent()
    }
    
    private func markLoadEnd() {
        loadEnd = CFAbsoluteTimeGetCurrent()
        guard let start = loadStart, let end = loadEnd else {
            return
        }
        navigationItem.title = "\(end - start)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        defer {
            apply(theme: theme)
        }

        view.addConstrainedSubview(webView)

        guard let mobileHTMLURL = mobileHTMLURL else {
            return
        }

        var request = URLRequest(url: mobileHTMLURL, permanentlyPersistedCachePolicy: .ignorePermanentlyPersistedCacheData)
        if let variant = preferredVariant(for: articleURL) {
            request.setValue(variant, forHTTPHeaderField: "Accept-Language")
        }
        markLoadStart()
        webView.load(request)
      

        configureCloseButton()
        configureToolbar()
    }

    private func configureCloseButton() {
        if presentingViewController != nil {
            let closeButton = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissAnimated))
            closeButton.accessibilityIdentifier = "close"
            navigationItem.rightBarButtonItem = closeButton
        }
    }

    private func configureToolbar() {
        navigationController?.isToolbarHidden = false

        let tableOfContents = UIBarButtonItem(image: UIImage(named: "toc"), style: .plain, target: self, action: #selector(openTableOfContents))
        let language = UIBarButtonItem(image: UIImage(named: "language"), style: .plain, target: self, action: #selector(changeLanguage))
        let save = UIBarButtonItem(image: articleCacheController.isCached(articleURL) ? UIImage(named: "save-filled") : UIImage(named: "save"), style: .plain, target: self, action: #selector(saveOrUnsave))
        let scrollToBottom = UIBarButtonItem(image: UIImage(named: "direction-down"), style: .plain, target: self, action: #selector(self.scrollToBottom))
        language.isEnabled = false

        setToolbarItems([tableOfContents, language, save, scrollToBottom], animated: true)
    }

    @objc private func openTableOfContents() {

    }

    @objc private func changeLanguage() {

    }

    @objc private func saveOrUnsave() {

    }

    @objc private func scrollToBottom() {
        webView.evaluateJavaScript("window.scrollTo(0, document.scrollingElement.scrollHeight)")
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

    @objc private func dimImagesWasUpdated(_ notification: Notification) {
        guard let dimImages = notification.object as? Bool else {
            return
        }
        webView.evaluateJavaScript(ThemeJavaScript.dimImages(dimImages))
    }

    private var loadRetryCount = 0
    private let maxLoadRetryCount = 3
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let requestError = RequestError.from(code: (error as NSError).code) else {
            showAlert(forError: error)
            return
        }
        switch requestError {
        case .timeout where loadRetryCount == maxLoadRetryCount:
            showAlert(forError: error)
            loadRetryCount = 0
        case .timeout:
            defer {
                loadRetryCount += 1
            }
            guard let mobileHTMLURL = mobileHTMLURL else {
                showAlert(forError: NSError(domain: "org.wikimedia.lite", code: NSURLErrorBadURL, userInfo: nil))
                return
            }
            let request = URLRequest(url: mobileHTMLURL, permanentlyPersistedCachePolicy: .usePermanentlyPersistedCacheData)
            webView.load(request)
        default:
            break
        }
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
            defer {
                loadRetryCount += 1
            }
            guard let mobileHTMLURL = mobileHTMLURL else {
                showAlert(forError: NSError(domain: "org.wikimedia.lite", code: NSURLErrorBadURL, userInfo: nil))
                return
            }
            let request = URLRequest(url: mobileHTMLURL, permanentlyPersistedCachePolicy: .usePermanentlyPersistedCacheData)
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
        evaluateJavaScript(ThemeJavaScript.set(theme: theme))
    }
}

private extension URL {
    func replacingPageTitle(_ oldTitle: String, with newTitle: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.path = path.replacingOccurrences(of: oldTitle, with: newTitle.replacingOccurrences(of: " ", with: "_"))
        return components?.url
    }
}

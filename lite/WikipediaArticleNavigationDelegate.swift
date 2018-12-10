import UIKit
import WebKit

extension URL {
    var appSchemeArticleURL: URL? {
        guard host?.hasSuffix("wikipedia.org") ?? false else {
            return nil
        }
        
        guard pathComponents.count > 1, pathComponents[1] == "wiki", let title = pathComponents.last?.trimmingCharacters(in: WikipediaArticleNavigationDelegate.slashCharacterSet) else {
            return nil
        }
        
        guard var adjustedComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        adjustedComponents.path = ["", "api", "rest_v1", "page", "mobile-html", title].joined(separator: "/")
        
        return adjustedComponents.url
    }
}

class WikipediaArticleNavigationDelegate: NSObject, WKNavigationDelegate {
    let configuration = Configuration.current
    
    static let slashCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "/")
    }()
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
        guard pathComponents.count > 1, pathComponents[1] == "wiki", let title = pathComponents.last?.trimmingCharacters(in: WikipediaArticleNavigationDelegate.slashCharacterSet) else {
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
        webView.load(adjustedRequest)
    }
}

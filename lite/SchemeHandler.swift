import WebKit

enum SchemeHandlerError: Error {
    case invalidParameters
    
    var localizedDescription: String {
        return NSLocalizedString("An unexpected error has occurred.", comment: "¯\\_(ツ)_/¯")
    }
}
class SchemeHandler: NSObject {
    let scheme: String
    let session: Session
    var tasks: [URLRequest: URLSessionTask] = [:]
    var queue: DispatchQueue = DispatchQueue(label: "SchemeHandlerQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    
    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
    }
}

extension SchemeHandler: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        var request = urlSchemeTask.request
        guard let requestURL = request.url else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        guard let components = NSURLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
            urlSchemeTask.didFailWithError(SchemeHandlerError.invalidParameters)
            return
        }
        #if WMF_LOCAL
        components.scheme = components.host == "localhost" ? "http" : "https"
        #else
        components.scheme =  "https"
        #endif
        guard let url = components.url else {
            return
        }
        request.url = url
        let callback = Callback(
            response: { response in
                urlSchemeTask.didReceive(response)
            },
            data: { data in
                urlSchemeTask.didReceive(data)
            },
            success: {
                urlSchemeTask.didFinish()
            },
            failure: { error in
                urlSchemeTask.didFailWithError(error)
            }
        )
            
        let task = session.executeDataTaskWith(request, callback: callback)
        queue.async(flags: .barrier) {
            self.tasks[urlSchemeTask.request] = task
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        queue.async(flags: .barrier) {
            guard let task = self.tasks[urlSchemeTask.request] else {
                return
            }
            task.cancel()
            self.tasks.removeValue(forKey: urlSchemeTask.request)
        }
    }
}


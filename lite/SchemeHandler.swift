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

        let callback = Session.Callback(response: { task, response in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                urlSchemeTask.didFailWithError(error)
            } else {
                urlSchemeTask.didReceive(response)
            }
        }, data: { data in
            urlSchemeTask.didReceive(data)
        }, success: {
            urlSchemeTask.didFinish()
        }) { task, error in
            task.cancel()
            urlSchemeTask.didFailWithError(error)
        }
        let task = session.dataTaskWith(request, callback: callback)
        queue.async(flags: .barrier) {
            self.tasks[urlSchemeTask.request] = task
        }
        task.resume()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        queue.async(flags: .barrier) {
            guard let task = self.tasks[urlSchemeTask.request] else {
                return
            }
            if task.state == .running {
                task.cancel()
            }
            self.tasks.removeValue(forKey: urlSchemeTask.request)
        }
    }
}


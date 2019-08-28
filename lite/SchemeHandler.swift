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
    private var activeSchemeTasks = NSMutableSet(array: [])

    required init(scheme: String, session: Session) {
        self.scheme = scheme
        self.session = session
    }
    
    func addSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        activeSchemeTasks.add(urlSchemeTask)
    }
    
    func removeSchemeTask(urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        activeSchemeTasks.remove(urlSchemeTask)
    }
    
    func schemeTaskIsActive(urlSchemeTask: WKURLSchemeTask) -> Bool {
        assert(Thread.isMainThread)
        return activeSchemeTasks.contains(urlSchemeTask)
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

        if components.path?.contains("html/to/mobile-html") ?? false {
            request.httpMethod = "POST"
            request.httpBody = try! Data(contentsOf: Bundle.main.url(forResource: "dog", withExtension: "html")!)
            request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        }
        request.url = url

        let callback = Session.Callback(response: { [weak urlSchemeTask] task, response in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                        return
                    }
                    urlSchemeTask.didFailWithError(error)
                    self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
                }
            } else {
                DispatchQueue.main.async {
                    guard let urlSchemeTask = urlSchemeTask else {
                        return
                    }
                    guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                        return
                    }
                    urlSchemeTask.didReceive(response)
                }
            }
        }, data: { [weak urlSchemeTask] data in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didReceive(data)
            }
        }, success: { [weak urlSchemeTask] in
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didFinish()
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }) { [weak urlSchemeTask] task, error in
            task.cancel()
            DispatchQueue.main.async {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard self.schemeTaskIsActive(urlSchemeTask: urlSchemeTask) else {
                    return
                }
                urlSchemeTask.didFailWithError(error)
                self.removeSchemeTask(urlSchemeTask: urlSchemeTask)
            }
        }
        
        addSchemeTask(urlSchemeTask: urlSchemeTask)
        let task = session.dataTaskWith(request, callback: callback)
        self.tasks[urlSchemeTask.request] = task

        task.resume()
    }
    
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        guard let task = self.tasks[urlSchemeTask.request] else {
            return
        }
        if task.state == .running {
            task.cancel()
        }
        self.tasks.removeValue(forKey: urlSchemeTask.request)
    }
}


import Foundation

struct Callback {
    let response: ((URLResponse) -> Void)?
    let data: ((Data) -> Void)?
    let success: (() -> Void)
    let failure: ((Error) -> Void)
}

public class Session: NSObject {
    let sessionConfiguration: URLSessionConfiguration
    let sessionDelegate: SessionDelegate
    let session: URLSession
    
    enum Result<T> {
        case success(result: T)
        case failure(error: Error)
    }
    
    override init() {
        sessionConfiguration = URLSessionConfiguration.default
        sessionDelegate = SessionDelegate()
        session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: sessionDelegate.delegateQueue)
    }
    
    func executeDataTaskWith(_ request: URLRequest, callback: Callback) -> URLSessionTask {
        let task = session.dataTask(with: request)
        sessionDelegate.addCallback(callback: callback, for: task)
        task.resume()
        return task
    }
}

class SessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    let delegateDispatchQueue = DispatchQueue(label: "SessionDelegateDispatchQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    let delegateQueue: OperationQueue
    var callbacks: [Int: Callback] = [:]
    
    override init() {
        delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue = delegateDispatchQueue
    }
    
    func addCallback(callback: Callback, for task: URLSessionTask) {
        delegateDispatchQueue.async(flags: .barrier) {
            self.callbacks[task.taskIdentifier] = callback
        }
    }
    
    func removeDataCallback(for task: URLSessionTask) {
        delegateDispatchQueue.async(flags: .barrier) {
            self.callbacks.removeValue(forKey: task.taskIdentifier)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        defer {
            completionHandler(.allow)
        }
        guard let callback = callbacks[dataTask.taskIdentifier]?.response else {
            return
        }
        callback(response)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let callback = callbacks[dataTask.taskIdentifier]?.data else {
            return
        }
        callback(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            removeDataCallback(for: task)
        }
        
        guard let callback = callbacks[task.taskIdentifier] else {
            return
        }
        
        if let error = error as NSError? {
            if error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled {
                callback.failure(error)
            }
            return
        }
        
        callback.success()
    }
}

public enum RequestError: LocalizedError {
    case unknown
    case invalidParameters
    case unexpectedResponse
    case noNewData
    public var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "The app received an unexpected response from the server. Please try again later."
        default:
            return "Something went wrong. Please try again later."
        }
    }
}

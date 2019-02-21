import UIKit

// Base class for combining a Session and Configuration to make network requests
// Session handles constructing and making requests, Configuration handles url structure for the current target

// TODO: Standardize on returning CancellationKey or URLSessionTask
// TODO: Centralize cancellation and remove other cancellation implementations (ReadingListsAPI)
// TODO: Remove CSRFTokenOperation and create other new methods here for token generation and use
// TODO: Think about utilizing a request buildler instead of so many separate functions
// TODO: Utilize Result type where possible (Swift only)

@objc(WMFFetcher)
open class Fetcher: NSObject {
    @objc public let configuration: Configuration
    @objc public let session: Session

    public typealias CancellationKey = String
    
    private var tasks = [String: URLSessionTask]()
    private let semaphore = DispatchSemaphore.init(value: 1)
    
    @objc required public init(session: Session, configuration: Configuration) {
        self.session = session
        self.configuration = configuration
    }
    
    @objc(trackTask:forKey:)
    public func track(task: URLSessionTask?, for key: String) {
        guard let task = task else {
            return
        }
        semaphore.wait()
        tasks[key] = task
        semaphore.signal()
    }
    
    @objc(untrackTaskForKey:)
    public func untrack(taskFor key: String) {
        semaphore.wait()
        tasks.removeValue(forKey: key)
        semaphore.signal()
    }
    
    @objc(cancelTaskForKey:)
    public func cancel(taskFor key: String) {
        semaphore.wait()
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
        semaphore.signal()
    }
    
    @objc(cancelAllTasks)
    public func cancelAllTasks() {
        semaphore.wait()
        for (_, task) in tasks {
            task.cancel()
        }
        tasks.removeAll(keepingCapacity: true)
        semaphore.signal()
    }
}

// These are for bridging to Obj-C only
@objc public extension Fetcher {
    @objc public class var unexpectedResponseError: NSError {
        return RequestError.unexpectedResponse as NSError
    }
    @objc public class var invalidParametersError: NSError {
        return RequestError.invalidParameters as NSError
    }
    @objc public class var noNewDataError: NSError {
        return RequestError.noNewData as NSError
    }
    @objc public class var cancelledError: NSError {
        return NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: [NSLocalizedDescriptionKey: RequestError.unexpectedResponse.localizedDescription])
    }
}

@objc(WMFTokenType)
public enum TokenType: Int {
    case csrf, login, createAccount
    var stringValue: String {
        switch self {
        case .login:
            return "login"
        case .createAccount:
            return "createaccount"
        case .csrf:
            return "csrf"
        }
    }
    var parameterName: String {
        switch self {
        case .login:
            return "logintoken"
        case .createAccount:
            return "createtoken"
        default:
            return "token"
        }
    }
}

@objc(WMFToken)
public class Token: NSObject {
    @objc public var token: String
    @objc public var type: TokenType
    public var isAuthorized: Bool
    @objc init(token: String, type: TokenType) {
        self.token = token
        self.type = type
        self.isAuthorized = token != "+\\"
    }
}

public enum FetcherResult<Success, Error> {
    case success(Success)
    case failure(Error)
}

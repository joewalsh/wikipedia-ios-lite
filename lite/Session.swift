import Foundation

struct Callback {
    let response: ((URLResponse) -> Void)?
    let data: ((Data) -> Void)?
    let success: (() -> Void)
    let failure: ((Error) -> Void)
}

public class Session: NSObject {
    let sessionConfiguration: URLSessionConfiguration
    let session: URLSession
    
    enum Result<T> {
        case success(result: T)
        case failure(error: Error)
    }
    
    override init() {
        sessionConfiguration = URLSessionConfiguration.default
        session = URLSession(configuration: sessionConfiguration)
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return session.downloadTask(with: url, completionHandler: completionHandler)
    }
}

public enum RequestError: Int, LocalizedError {
    case unknown
    case invalidParameters
    case unexpectedResponse
    case noNewData
    case timeout = 504
    
    public var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "The app received an unexpected response from the server. Please try again later."
        default:
            return "Something went wrong. Please try again later."
        }
    }

    static func from(code: Int) -> RequestError? {
        return self.init(rawValue: code)
    }
}
}

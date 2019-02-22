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

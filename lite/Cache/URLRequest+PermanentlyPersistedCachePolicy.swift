import Foundation

public extension URLRequest {
    enum PermanentlyPersistedCachePolicy: String {
        case ignorePermanentlyPersistedCacheData
        case usePermanentlyPersistedCacheData
    }

    private static let permanentlyPersistedCachePolicyHeader = "Permanently-Persisted-Cache-Control"

    init(url: URL, permanentlyPersistedCachePolicy: PermanentlyPersistedCachePolicy) {
        self.init(url: url)
        setValue(permanentlyPersistedCachePolicy.rawValue, forHTTPHeaderField: URLRequest.permanentlyPersistedCachePolicyHeader)
    }

    var permanentlyPersistedCachePolicy: PermanentlyPersistedCachePolicy? {
        guard let rawValue = value(forHTTPHeaderField: URLRequest.permanentlyPersistedCachePolicyHeader) else {
            return nil
        }
        return PermanentlyPersistedCachePolicy(rawValue: rawValue)
    }
}

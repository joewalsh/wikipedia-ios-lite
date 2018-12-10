import UIKit

class PermanentlyPersistableURLCache: URLCache {
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        return super.cachedResponse(for: request)
    }
}

import UIKit

class PermanentlyPersistableURLCache: URLCache {
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let response = super.cachedResponse(for: request) else {
            // return permanenently cashed response
            return nil
        }
        return response
    }
}

import UIKit

protocol PermanentlyPersistableURLCacheDelegate: AnyObject {
    func permanentlyPersistedResponse(for url: URL) -> CachedURLResponse?
    func temporaryCachedResponseWithLocalFile(for url: URLRequest) -> CachedURLResponse?
}

class PermanentlyPersistableURLCache: URLCache {
    weak var delegate: PermanentlyPersistableURLCacheDelegate?

    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        if let response = delegate?.temporaryCachedResponseWithLocalFile(for: request) {
            return response
        }
        print("PermanentlyPersistableURLCache: asking for cachedResponse for request with url: \(request.url!)")
        guard let response = super.cachedResponse(for: request) else {
            guard let url = request.url else {
                return nil
            }
            guard let response = delegate?.permanentlyPersistedResponse(for: url) else {
                return nil
            }
            return response
        }
        print("PermanentlyPersistableURLCache: has cached data for for url \(request.url!)")
        return response
    }
}

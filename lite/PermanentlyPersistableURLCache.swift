import UIKit

protocol PermanentlyPersistableURLCacheDelegate: AnyObject {
    func permanentlyPersistedData(for url: URL) -> Data?
}

class PermanentlyPersistableURLCache: URLCache {
    weak var delegate: PermanentlyPersistableURLCacheDelegate?

    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let response = super.cachedResponse(for: request) else {
            guard let url = request.url else {
                return nil
            }
            guard let data = delegate?.permanentlyPersistedData(for: url) else {
                return nil
            }
            // don't set mimeType here, do it in cache controller
            let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: nil)
            return CachedURLResponse(response: response, data: data)
        }
        return response
    }
}

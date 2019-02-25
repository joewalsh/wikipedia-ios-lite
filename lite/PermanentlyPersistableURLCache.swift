import UIKit

protocol PermanentlyPersistableURLCacheDelegate: AnyObject {
    func permanentlyPersistedData(for url: URL) -> Data?
}

class PermanentlyPersistableURLCache: URLCache {
    weak var delegate: PermanentlyPersistableURLCacheDelegate?

    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        print("PermanentlyPersistableURLCache: asking for cachedResponse for request with url: \(request.url!)")
        guard let response = super.cachedResponse(for: request) else {
            guard let url = request.url else {
                return nil
            }
            guard let data = delegate?.permanentlyPersistedData(for: url) else {
                print("PermanentlyPersistableURLCache: no permanently persisted data for \(url), returning nil")
                return nil
            }
            print("PermanentlyPersistableURLCache: has permanently persisted data for url \(url), returning cached response with data")
            // don't set mimeType here, do it in cache controller
            let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: nil)
            return CachedURLResponse(response: response, data: data)
        }
        print("PermanentlyPersistableURLCache: has cached data for for url \(request.url!)")
        return response
    }
}

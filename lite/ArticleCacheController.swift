import Foundation


class ArticleCacheController: NSObject {
    static let articleCacheWasUpdatedNotification = Notification.Name("ArticleCachWasUpdated")
    static let articleCacheWasUpdatedArticleURLKey = "ArticleCachWasUpdatedArticleURLKey"
    static let articleCacheWasUpdatedIsCachedKey = "ArticleCachWasUpdatedIsCachedKey"

    let cacheURL: URL
    let fileManager = FileManager.default

    override init() {
        guard
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        else {
            fatalError()
        }
        let documentsURL = URL(fileURLWithPath: documentsPath)
        self.cacheURL = documentsURL.appendingPathComponent("Article Cache", isDirectory: true)
        do {
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    func cacheArticle(articleURL: URL, data: Data) {
        // move to bg
        let path = cacheFilePath(for: articleURL)
        let cached = (data as NSData).write(toFile: path, atomically: true)
        assert(cached)
        let userInfo: [String: Any] = [
            ArticleCacheController.articleCacheWasUpdatedArticleURLKey: articleURL,
            ArticleCacheController.articleCacheWasUpdatedIsCachedKey: cached
        ]
        NotificationCenter.default.post(name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil, userInfo: userInfo)
    }

    func cachedArticleData(articleURL: URL) -> Data? {
        print(articleURL)
        return nil
    }

    func removeCachedArticleData(articleURL: URL) {
        let cachedArticleURL = cacheFileURL(for: articleURL)
        do {
            try fileManager.removeItem(at: cachedArticleURL)

            let userInfo: [String: Any] = [
                ArticleCacheController.articleCacheWasUpdatedArticleURLKey: articleURL,
                ArticleCacheController.articleCacheWasUpdatedIsCachedKey: false
            ]
            NotificationCenter.default.post(name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil, userInfo: userInfo)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    private func cacheKey(for url: URL) -> String {
        return url.path.replacingOccurrences(of: "/", with: "_")
    }

    private func cacheFilePath(for url: URL) -> String {
        return cacheFileURL(for: url).path
    }

    private func cacheFileURL(for url: URL) -> URL {
        let key = cacheKey(for: url)
        return cacheURL.appendingPathComponent(key, isDirectory: false)
    }

    func isCached(url: URL) -> Bool {
        return fileManager.fileExists(atPath: cacheFilePath(for: url))
    }
}
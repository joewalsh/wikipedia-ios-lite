import Foundation

final class ArticlesController: NSObject {
    let fetcher: ArticleFetcher
    let cacheController: ArticleCacheController

    init(fetcher: ArticleFetcher, cacheController: ArticleCacheController) {
        self.fetcher = fetcher
        self.cacheController = cacheController
        super.init()
    }

    func toggleCache(for articleURL: URL) {
        print("ArticlesController: toggled cache for \(articleURL)")
        let isCached = cacheController.isCached(articleURL)
        if isCached {
            print("ArticlesController: cache for \(articleURL) exists, removing")
            cacheController.removeCachedArticle(with: articleURL)
        } else {
            fetcher.downloadHTMLAndSaveToFile(for: articleURL) { error, fileURL in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                guard let fileURL = fileURL else {
                    fatalError()
                }
                self.cacheController.moveArticleHTMLFileToCache(fileURL: fileURL, withContentsOf: articleURL)
    private func downloadArticleResourceAndCache(_ resource: Configuration.MobileAppsServices.Page.Resource, for articleURL: URL) {
        fetcher.downloadArticleResource(resource, for: articleURL) { error, temporaryFileURL, resourceURL in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            guard let temporaryFileURL = temporaryFileURL, let resourceURL = resourceURL else {
                fatalError()
            }
            self.cacheController.moveTemporaryFileToCache(temporaryFileURL: temporaryFileURL, withContentsOf: resourceURL) { error, key in
                self.cacheController.addCacheItemToCacheGroup(for: articleURL, cacheItemKey: key)
            }
        }
    }
        }
    }
}

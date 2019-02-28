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
            print("ArticlesController: cache for \(articleURL) doesn't exist, fetching")
            cacheController.cacheResource(.mobileHTML, for: articleURL)
            cacheController.cacheResource(.references, for: articleURL)
            cacheController.cacheResource(.sections, for: articleURL)
            cacheController.cacheMedia(for: articleURL)
        }
    }
}

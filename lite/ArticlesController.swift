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
            downloadArticleResourceAndCache(.mobileHTML, for: articleURL)
            downloadArticleResourceAndCache(.references, for: articleURL)
            downloadArticleResourceAndCache(.sections, for: articleURL)
            // media response needs to be decoded to cache individual files
            // should be separated?
            fetcher.getMedia(for: articleURL) { error, media in
                assert(error == nil)
                print(media)
            }
        }
    }

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

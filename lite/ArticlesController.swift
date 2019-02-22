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
        let isCached = cacheController.isCached(url: articleURL)
        if isCached {
            cacheController.removeCachedArticleData(articleURL: articleURL)
        } else {
            fetcher.downloadHTMLAndSaveToFile(for: articleURL) { error, fileURL in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                guard let fileURL = fileURL else {
                    fatalError()
                }
                self.cacheController.moveArticleHTMLFileToCache(fileURL: fileURL, withContentsOf: articleURL)
            }
        }
    }
}

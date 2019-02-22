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
            let callback = Callback(response: { (response) in
                //
            }, data: { (data) in
                self.cacheController.cacheArticle(articleURL: articleURL, data: data)
            }, success: {
                //
            }) { (error) in
                fatalError(error.localizedDescription)
            }
            fetcher.fetchHTML(for: articleURL, callback: callback)
        }
    }
}

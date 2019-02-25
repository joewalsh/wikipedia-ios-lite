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
            fetcher.getMedia(for: articleURL) { data, response, error in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                guard let response = response as? HTTPURLResponse else {
                    assertionFailure("Expected HTTP response")
                    return
                }
                guard response.statusCode == 200 else {
                    assertionFailure("Expected 200 status code, got \(response.statusCode)")
                    return
                }
                guard let data = data else {
                    assertionFailure("Expected data, got nil")
                    return
                }
                let decoder = JSONDecoder()
                let media = try? decoder.decode(Media.self, from: data)
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

private struct Media: Decodable {
    let revision: String?
    let tid: String?
    let items: [Item]?

    struct Item: Decodable {
        let sectionID: UInt?
        let type: String?
        let caption: Info?
        let showInGallery: Bool?
        let titles: Titles?
        let thumbnail: Image?
        let original: Image?
        let filePage: String?
        let artist: Info?
        let credit: Info?
        let license: License?
        let description: Info?

        enum CodingKeys: String, CodingKey {
            case sectionID = "section_id"
            case type
            case caption
            case showInGallery
            case titles
            case thumbnail
            case original
            case filePage = "file_page"
            case artist
            case credit
            case license
            case description
        }

        struct Info: Decodable {
            let html: String?
            let text: String?
        }

        struct Titles: Decodable {
            let canonical: String?
            let normalized: String?
            let display: String?
        }

        struct Image: Decodable {
            let source: String?
            let width: UInt?
            let height: UInt?
            let mime: String?
        }

        struct License: Decodable {
            let type: String?
            let code: String?
        }
    }
}

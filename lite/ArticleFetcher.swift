import Foundation

class ArticleFetcher: Fetcher {
    typealias Resource = Configuration.MobileAppsServices.Page.Resource
    typealias CSS = Configuration.MobileAppsServices.Data.CSS
    typealias RequestURL = URL
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, RequestURL?, TemporaryFileURL?, MIMEType?) -> Void

    private var scheme: String {
        switch Configuration.Stage.current {
        case .local:
            return Configuration.Scheme.http
        default:
            return Configuration.Scheme.https
        }
    }

    // MARK: Resources

    func downloadResource(_ resource: Resource, for articleURL: URL, completion: @escaping DownloadCompletion) {
        guard let url = configuration.mobileAppsServicesArticleResourceURLForArticle(with: articleURL, scheme: scheme, resource: resource) else {
            completion(Fetcher.invalidParametersError, nil, nil, nil)
            return
        }

        session.downloadTask(with: url) { fileURL, response, error in
            if let error = error {
                completion(error, url, nil, response?.mimeType)
                return
            }
            guard let fileURL = fileURL, response != nil else {
                completion(Fetcher.unexpectedResponseError, url, nil, response?.mimeType)
                return
            }
            completion(nil, url, fileURL, response?.mimeType)
        }.resume()
    }

    func downloadImage(_ url: URL, completion: @escaping (Error?, URL?) -> Void) {
        session.downloadTask(with: url) { fileURL, response, error in
            if let error = error {
                completion(error, nil)
                return
            }
            guard let fileURL = fileURL, response != nil else {
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            completion(nil, fileURL)
        }.resume()
    }

    struct Media: Decodable {
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

    func getMedia(for articleURL: URL, completion: @escaping (Error?, Media?) -> Void) {
        let url = configuration.mobileAppsServicesArticleResourceURLForArticle(with: articleURL, scheme: scheme, resource: .media)!
        session.session.dataTask(with: url) { data, response, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                completion(error, nil)
            }
            guard let response = response as? HTTPURLResponse else {
                assertionFailure("Expected HTTP response")
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            guard response.statusCode == 200 else {
                assertionFailure("Expected 200 status code, got \(response.statusCode)")
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            guard let data = data else {
                assertionFailure("Expected data, got nil")
                completion(Fetcher.noNewDataError, nil)
                return
            }
            let decoder = JSONDecoder()
            let media = try? decoder.decode(Media.self, from: data)
            completion(nil, media)
        }.resume()
    }
}

import Foundation

class ArticleFetcher: Fetcher {
    typealias Resource = Configuration.MobileAppsServices.Page.Resource
    typealias Data = Configuration.MobileAppsServices.Data
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

    #warning("Add a method to fetch the latest version of article")

    // MARK: Resources

    func downloadResource(_ resource: Resource, for articleURL: URL, completion: @escaping DownloadCompletion) {
        guard let url = configuration.mobileAppsServicesPageResourceURLForArticle(with: articleURL, scheme: scheme, resource: resource) else {
            completion(Fetcher.invalidParametersError, nil, nil, nil)
            return
        }

        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(articleURL: articleURL, url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        track(task: task, forGroupWithKey: articleURL.key, taskKey: url.key)
        task.resume()
    }

    // MARK: Data

    func downloadData(_ data: Data, for articleURL: URL, completion: @escaping DownloadCompletion) {
        guard let url = configuration.mobileAppsServicesPageDataURLForArticle(with: articleURL, data: data, scheme: scheme) else {
            completion(Fetcher.invalidParametersError, nil, nil, nil)
            return
        }
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(articleURL: articleURL, url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        track(task: task, forGroupWithKey: articleURL.key, taskKey: url.key)
        task.resume()
    }

    private func handleDownloadTaskCompletion(articleURL: URL, url: URL, fileURL: URL?, response: URLResponse?, error: Error?, completion: @escaping DownloadCompletion) {
        if let error = error {
            self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
            completion(error, url, nil, nil)
            return
        }
        guard let fileURL = fileURL, let response = response else {
            self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
            completion(Fetcher.unexpectedResponseError, url, nil, nil)
            return
        }
        completion(nil, url, fileURL, response.mimeType)
    }

    // MARK: Media

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
        let url = configuration.mobileAppsServicesPageResourceURLForArticle(with: articleURL, scheme: scheme, resource: .media)!
        let task = session.session.dataTask(with: url) { data, response, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
                completion(error, nil)
            }
            guard let response = response as? HTTPURLResponse else {
                assertionFailure("Expected HTTP response")
                self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            guard response.statusCode == 200 else {
                print("Expected 200 status code, got \(response.statusCode)")
                self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
                completion(Fetcher.unexpectedResponseError, nil)
                return
            }
            guard let data = data else {
                assertionFailure("Expected data, got nil")
                self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
                completion(Fetcher.noNewDataError, nil)
                return
            }
            let decoder = JSONDecoder()
            do {
                let media = try decoder.decode(Media.self, from: data)
                completion(nil, media)
            } catch let error {
                self.untrack(taskForGroupWithKey: articleURL.key, taskKey: url.key)
                completion(error, nil)
            }
        }
        track(task: task, forGroupWithKey: articleURL.key, taskKey: url.key)
        task.resume()
    }

    func downloadImage(_ url: URL, forArticleWithURL articleURL: URL, completion: @escaping DownloadCompletion) {
        let task = session.downloadTask(with: url) { fileURL, response, error in
            self.handleDownloadTaskCompletion(articleURL: articleURL, url: url, fileURL: fileURL, response: response, error: error, completion: completion)
        }
        track(task: task, forGroupWithKey: articleURL.key, taskKey: url.key)
        task.resume()
    }
}

extension URL {
    var key: String {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        guard let key = components?.url?.absoluteString.precomposedStringWithCanonicalMapping else {
            return absoluteString.precomposedStringWithCanonicalMapping
        }
        return key
    }
}

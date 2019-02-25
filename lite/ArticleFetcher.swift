import Foundation

class ArticleFetcher: Fetcher {
    typealias Resource = Configuration.MobileAppsServices.Page.Resource
    typealias DownloadCompletion = (Error?, URL?, URL?) -> Void

    private var scheme: String {
        switch Configuration.Stage.current {
        case .local:
            return Configuration.Scheme.http
        default:
            return Configuration.Scheme.https
        }
    }

    func downloadArticleResource(_ resource: Configuration.MobileAppsServices.Page.Resource, for articleURL: URL, completion: @escaping DownloadCompletion) {
        guard let url = configuration.mobileAppsServicesArticleResourceURLForArticle(with: articleURL, scheme: scheme, resource: resource) else {
            completion(Fetcher.invalidParametersError, nil, nil)
            return
        }

        session.downloadTask(with: url) { (fileURL, response, error) in
            if let error = error {
                completion(error, nil, url)
                return
            }
            guard let fileURL = fileURL, response != nil else {
                completion(Fetcher.unexpectedResponseError, nil, url)
                return
            }
            completion(nil, fileURL, url)
        }.resume()
    }
}

import Foundation

class ArticleFetcher: Fetcher {
    typealias Resource = Configuration.MobileAppsServices.Page.Resource
    typealias DownloadCompletion = (Error?, URL?, URL?) -> Void

    func downloadHTMLAndSaveToFile(for articleURL: URL, completion: @escaping (Error?, URL?) -> Void) {
        session.downloadTask(with: articleURL) { (fileURL, response, error) in
    private var scheme: String {
        switch Configuration.Stage.current {
        case .local:
            return Configuration.Scheme.http
        default:
            return Configuration.Scheme.https
        }
    }
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
}

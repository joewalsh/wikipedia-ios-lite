import Foundation

class ArticleFetcher: Fetcher {

    func downloadHTMLAndSaveToFile(for articleURL: URL, completion: @escaping (Error?, URL?) -> Void) {
        session.session.downloadTask(with: articleURL) { (fileURL, response, error) in
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

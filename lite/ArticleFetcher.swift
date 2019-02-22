import Foundation

class ArticleFetcher: Fetcher {

    func fetchHTML(for articleURL: URL, callback: Callback) {
        let request = URLRequest(url: articleURL)
        session.executeDataTaskWith(request, callback: callback)
    }
}

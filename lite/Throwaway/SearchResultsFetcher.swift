import Foundation

public typealias Page = SearchResultsFetcher.Response.Query.Page

public class SearchResultsFetcher: Fetcher {

    public struct Response: Decodable {
        let query: Query?

        public struct Query: Decodable {
            let pages: [Page]?

            public struct Page: Decodable {
                let title: String?
            }

            enum CodingKeys: String, CodingKey {
                case pages
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let pages: Dictionary<String, Page> = try values.decode(Dictionary.self, forKey: .pages)
                self.pages = Array(pages.values)
            }
        }
    }

    func results(for term: String, completion: @escaping (Result<[Page], Error>) -> Void) {
        let params: [String: Any] = [
            "action": "query",
            "format": "json",
            "gpsnamespace": 0,
            "generator": "prefixsearch",
            "gpssearch": "\(term)"
        ]
        guard let url = configuration.mediaWikiAPIURForHost(with: params).url else {
            completion(.failure(Fetcher.invalidParametersError))
            return
        }
        session.session.dataTask(with: url) { data, response, error in
            if error != nil {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            guard httpResponse.statusCode == 200 else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            guard let data = data else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            completion(.success(response.query?.pages ?? []))
        }.resume()
    }
}

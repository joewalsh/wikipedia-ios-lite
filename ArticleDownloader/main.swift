import Foundation

struct Article {
    let language: String
    let title: String
}

let articles = [
    Article(language: "en", title: "United_States"),
    Article(language: "en", title: "Dog"),
    Article(language: "en", title: "Stephen_Hawking"),
    Article(language: "de", title: "Stephen_Hawking"),
    Article(language: "fr", title: "Stephen_Hawking"),
    Article(language: "es", title: "Stephen_Hawking"),
    Article(language: "it", title: "Stephen_Hawking"),
    Article(language: "zh", title: "Stephen_Hawking")
]


let outputFolder = URL(fileURLWithPath: ("~/Desktop/mobile-html-offline" as NSString).expandingTildeInPath)

for article in articles {
    let languageFolder = outputFolder.appendingPathComponent(article.language)
    try? FileManager.default.createDirectory(at: languageFolder, withIntermediateDirectories: true, attributes: nil)
    guard
        let encodedTitle = article.title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathComponentAllowed),
        let articleURL = URL(string: "https://\(article.language).wikipedia.org/api/rest_v1/page/mobile-html/\(encodedTitle)")
    else {
        continue
    }
    URLSession.shared.dataTask(with: articleURL) { (data, response, error) in
        let outputFileURL = languageFolder.appendingPathComponent("\(encodedTitle).html")
        try? FileManager.default.removeItem(at: outputFileURL)
        guard
            let data = data,
            var string = String(data: data, encoding: .utf8)
        else {
                return
        }
        string = string.replacingOccurrences(of: "<base href=\"//\(article.language).wikipedia.org/wiki/\">", with: "")
        string = string.replacingOccurrences(of: "//meta.wikimedia.org/api/rest_v1/data/css/mobile/base", with: "../base.css")
        string = string.replacingOccurrences(of: "//meta.wikimedia.org/api/rest_v1/data/css/mobile/pagelib", with: "../pagelib.css")
        string = string.replacingOccurrences(of: "//\(article.language).wikipedia.org/api/rest_v1/data/css/mobile/site", with: "site.css")
        string = string.replacingOccurrences(of: "//meta.wikimedia.org/api/rest_v1/data/javascript/mobile/pagelib", with: "../pagelib.js")
        let updatedData = string.data(using: .utf8)
        try? updatedData?.write(to: outputFileURL)
    }.resume()
}


dispatchMain()

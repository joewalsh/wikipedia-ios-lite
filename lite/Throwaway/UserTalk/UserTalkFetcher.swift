
import Foundation

class UserTalkFetcher: Fetcher {
    
    typealias Resource = Configuration.MobileAppsServices.Page.Resource
    typealias DiscussionFetchCompletion = (Error?, [Discussion]?) -> Void
    typealias CSSFetchCompletion = (Error?, [Data]?) -> Void
    
    private var scheme: String {
        switch Configuration.Stage.current {
        case .local:
            return Configuration.Scheme.http
        default:
            return Configuration.Scheme.https
        }
    }
    
    func fetchTalkPage(name: String, completion: @escaping DiscussionFetchCompletion) {
        //todo: this should go through a cache controller
        let articleUrl = URL(string: "https://en.wikipedia.org/wiki/\(name)")!
       
        guard let url = configuration.mobileAppsServicesArticleResourceURLForArticle(with: articleUrl, scheme: scheme, resource: .sections) else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }
        
        let request = URLRequest(url: url)
        let callback = Session.Callback(response: { task, response in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                completion(error, nil)
            } else {
                //nothing?
            }
        }, data: { data in
            if let root = try? JSONDecoder().decode(Root.self, from: data) {
                completion(nil, root.remaining.discussions)
                return
            }
            completion(nil, nil)
        }, success: {
            //nothing?
        }) { task, error in
            task.cancel()
            completion(error, nil)
        }
        
        
        let task = session.dataTaskWith(request, callback: callback)
        task.resume()
    }
    
    func fetchCSS(name: String, completion: @escaping CSSFetchCompletion) {
        //todo: this should go through a cache controller
        //todo: this should be optimized (dispatch group)
        let articleUrl = URL(string: "https://en.wikipedia.org/wiki/\(name)")!
        
        var cssData: [Data] = []
        fetchCSSJunk(articleUrl: articleUrl, css: .css(.base)) { [weak self] (error, data) in
            
            if let error = error {
                completion(error, nil)
                return
            }
            
            if let data = data {
                cssData.append(data)
            }
            
            self?.fetchCSSJunk(articleUrl: articleUrl, css: .css(.pagelib), completion: { [weak self] (error, data) in
                
                if let error = error {
                    completion(error, nil)
                    return
                }
                
                if let data = data {
                    cssData.append(data)
                }
                
                self?.fetchCSSJunk(articleUrl: articleUrl, css: .css(.site), completion: { (error, data) in
                    
                    if let error = error {
                        completion(error, nil)
                        return
                    }
                    
                    if let data = data {
                        cssData.append(data)
                        completion(nil, cssData)
                    }
                })
            })
        }
    }
    
    func fetchCSSJunk(articleUrl: URL, css: Configuration.MobileAppsServices.Data, completion: @escaping (_ error: Error?, _ data: Data?) -> Void) {
        //todo: this should go through a cache controller
        guard let url = configuration.mobileAppsServicesArticleDataURLForArticle(with: articleUrl, data: css, scheme: scheme) else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }
        let request = URLRequest(url: url)
        let callback = Session.Callback(response: { task, response in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = RequestError.from(code: httpResponse.statusCode) ?? .unknown
                task.cancel()
                completion(error, nil)
            } else {
                //nothing?
            }
        }, data: { data in
            completion(nil, data)
        }, success: {
            //nothing?
        }) { task, error in
            task.cancel()
            completion(error, nil)
        }
        
        let task = session.dataTaskWith(request, callback: callback)
        task.resume()
    }
}

private struct Root: Decodable {
    var remaining: Remaining
}

private struct Remaining: Decodable {
    var discussions: [Discussion]
    
    enum CodingKeys: String, CodingKey {
        case discussions = "sections"
    }
}

struct Discussion: Decodable {
    let id: Int
    let text: String
    let title: String
    
    //just a brute force attempt to split out <dl><dd></dl></dd> replies into their own items
    //would be good to actually keep the tree structure so we could indent if needed
    lazy var textItems: [String] = {
        
        //first try to split against <dl><dd></dl></dd>, otherwise split against <p></p>
        let firstSplitAttempt = splitOutItems(html: self.text, openingString: "<dl><dd>", closingString: "</dd></dl>")
        if firstSplitAttempt.count == 1,
            let firstSplit = firstSplitAttempt.first {
            let nextSplitAttempt = splitOutItems(html: firstSplit, openingString: "\n\n<p>", closingString: "</p>")
            return nextSplitAttempt.reversed()
        }
        
        return firstSplitAttempt
    }()
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case text = "text"
        case title = "line"
    }
    
    private func splitOutItems(html: String, openingString: String, closingString: String) -> [String] {
        
        var inputString = html
        var itemsToReturn: [String] = []
        while inputString.range(of: openingString) != nil {
            
            //if there are items after the last reply, cut and move to return items
            if let lastRangeOfClosingTags = inputString.range(of: closingString, options: .backwards, range: nil, locale: nil),
                !lastRangeOfClosingTags.isEmpty {
                
                //if there are items after the last reply, cut and move to return items
                let suffix = String(inputString.suffix(from: lastRangeOfClosingTags.upperBound))
                if !suffix.isEmpty {
                    inputString.removeLast(suffix.count)
                    itemsToReturn.insert(suffix, at: 0)
                    continue
                }
            }
            
            if let firstRangeOfClosingTags = inputString.range(of: closingString),
                !firstRangeOfClosingTags.isEmpty {
                
                let firstRangeClosingStartIndex = firstRangeOfClosingTags.lowerBound
                
                //get matching opening tag equivalent, remove from string
                if let lastRangeOfOpeningTags = inputString.prefix(upTo: firstRangeClosingStartIndex).range(of: openingString, options: .backwards, range: nil, locale: nil),
                    !lastRangeOfOpeningTags.isEmpty,
                    lastRangeOfOpeningTags.upperBound < firstRangeOfClosingTags.lowerBound {
                    
                    let range = Range.init(uncheckedBounds: (lower: lastRangeOfOpeningTags.lowerBound, upper: firstRangeOfClosingTags.upperBound))
                    
                    let startIndex = range.lowerBound
                    let endIndex = range.upperBound
                    
                    let string = String(inputString[startIndex..<endIndex])
                    itemsToReturn.insert(string, at: 0)
                    inputString.removeSubrange(range)
                } else {
                    print("invalid - closing tag exists without opening tag. exit early")
                    return [self.text]
                }
            } else {
                print("invalid - opening tag exists without closing tag. exit early")
                return [self.text]
            }
        }
        
        if !inputString.isEmpty {
            itemsToReturn.insert(inputString, at: 0)
        }
        return itemsToReturn.filter{$0 != "\n"}
    }
}

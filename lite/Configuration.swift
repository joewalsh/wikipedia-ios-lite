import Foundation

@objc(WMFConfiguration)
public class Configuration: NSObject {
    enum Stage {
        case production
        case labs
        case local
        
        static let current: Stage = {
            #if WMF_LOCAL
            return .local
            #elseif WMF_LABS
            return .labs
            #else
            return .production
            #endif
        }()
    }
    
    struct Scheme {
        static let http = "http"
        static let https = "https"
    }
    
    struct Domain {
        static let wikipedia = "wikipedia.org"
        static let wikidata = "wikidata.org"
        static let mediaWiki = "mediawiki.org"
        static let wmflabs = "wikipedia.beta.wmflabs.org"
        static let localhost = "localhost"
        static let englishWikipedia = "en.wikipedia.org"
        static let metaWiki = "meta.wikimedia.org"
    }
    
    struct Path {
        static let wikiResource = "/wiki/"
        static let mobileAppsServicesAPIComponents = ["api", "rest_v1"]
        static let mediaWikiAPIComponents = ["w", "api.php"]
    }
    
    public struct APIURLComponentsBuilder {
        let hostComponents: URLComponents
        let basePathComponents: [String]
        
        func components(byAppending pathComponents: [String] = [], queryParameters: [String: Any]? = nil) -> URLComponents {
            var components = hostComponents
            components.replacePercentEncodedPathWithPathComponents(basePathComponents + pathComponents)
            components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
            return components
        }
    }
   
    @objc public let defaultSiteDomain: String
    
    public let mediaWikiCookieDomain: String
    public let wikipediaCookieDomain: String
    public let wikidataCookieDomain: String
    public let centralAuthCookieSourceDomain: String // copy cookies from
    public let centralAuthCookieTargetDomains: [String] // copy cookies to
    
    public let wikiResourceDomains: [String]
    
    required init(defaultSiteDomain: String, otherDomains: [String] = []) {
        self.defaultSiteDomain = defaultSiteDomain
        self.mediaWikiCookieDomain = Domain.mediaWiki.withDotPrefix
        self.wikipediaCookieDomain = Domain.wikipedia.withDotPrefix
        self.wikidataCookieDomain = Domain.wikidata.withDotPrefix
        self.centralAuthCookieSourceDomain = self.wikipediaCookieDomain
        self.centralAuthCookieTargetDomains = [self.wikidataCookieDomain, self.mediaWikiCookieDomain]
        self.wikiResourceDomains = [defaultSiteDomain, Domain.mediaWiki] + otherDomains
    }
    
    func mobileAppsServicesAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        switch Stage.current {
        case .local:
            let host = host ?? Domain.englishWikipedia
            let baseComponents = [host, "v1"] // "" to get a leading /
            var components = URLComponents()
            components.scheme = Scheme.http
            components.host = Domain.localhost
            components.port = 6927
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: baseComponents)
        default:
            var components = URLComponents()
            components.host = host ?? Domain.englishWikipedia
            components.scheme = Scheme.https
            return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mobileAppsServicesAPIComponents)
        }
    }
    
    func mediaWikiAPIURLComponentsBuilderForHost(_ host: String? = nil) -> APIURLComponentsBuilder {
        var components = URLComponents()
        components.host = host ?? Domain.englishWikipedia
        components.scheme = Scheme.https
        return APIURLComponentsBuilder(hostComponents: components, basePathComponents: Path.mediaWikiAPIComponents)
    }

    @objc(mobileAppsServicesAPIURLComponentsForHost:appendingPathComponents:)
    public func mobileAppsServicesAPIURLComponentsForHost(_ host: String? = nil, appending pathComponents: [String] = [""]) -> URLComponents {
        let builder = mobileAppsServicesAPIURLComponentsBuilderForHost(host)
        return builder.components(byAppending: pathComponents)
    }

    static let slashCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "/")
    }()

    struct MobileAppsServices {
        struct Page {
            enum Resource: String {
                case mobileHTML = "mobile-html"
                case media
                case references
                case sections = "mobile-sections"
            }
        }
    }
    
    func mobileAppsServicesArticleURLForArticle(with url: URL, scheme: String) -> URL? {
        guard url.host?.hasSuffix("wikipedia.org") ?? false else {
            return nil
        }
        
        guard url.pathComponents.count > 1, url.pathComponents[1] == "wiki", let title = url.pathComponents.last?.trimmingCharacters(in: Configuration.slashCharacterSet) else {
            return nil
        }
        
        var components = mobileAppsServicesAPIURLComponentsForHost(url.host, appending: ["page", "mobile-html", title])
        
        components.scheme = scheme
        
        return components.url
    }
    
    @objc(mediaWikiAPIURLComponentsForHost:withQueryParameters:)
    public func mediaWikiAPIURForHost(_ host: String? = nil, with queryParameters: [String: Any]?) -> URLComponents {
        let builder = mediaWikiAPIURLComponentsBuilderForHost(host)
        return builder.components(queryParameters: queryParameters)
    }

    @objc public static let current: Configuration = {
        switch Stage.current {
        case .local:
            return Configuration(defaultSiteDomain: Domain.wikipedia)
        case .labs:
            return Configuration(defaultSiteDomain: Domain.wmflabs, otherDomains: [Domain.wikipedia])
        case .production:
            return Configuration(defaultSiteDomain: Domain.wikipedia)

        }
    }()
    
    @objc public func isWikiResource(_ url: URL?) -> Bool {
        guard url?.path.contains(Path.wikiResource) ?? false else {
            return false
        }
        guard let host = url?.host else { // relative paths should work
            return true
        }
        for domain in wikiResourceDomains {
            if host.isDomainOrSubDomainOf(domain) {
                return true
            }
        }
        return false
    }
    
}




import Foundation

extension CacheGroup {
    static func key(for url: URL) -> String {
        guard let keyComponents = url.keyComponents() else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        let keyComponentsCount = keyComponents.count
        // no page resource
        if keyComponentsCount == 2 {
            return keyComponents.joined(separator: "__")
            // page resource is included, don't included in the key
        } else if keyComponentsCount == 3 {
            return [keyComponents[0], keyComponents[2]].joined(separator: "__")
        } else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
    }
}

extension CacheItem {
    static func key(for url: URL, includingVariantIfAvailable includingVariant: Bool = true) -> String {
        guard let keyComponents = url.keyComponents(includingVariant: includingVariant) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return keyComponents.joined(separator: "__")
    }
}

private extension URL {
    func pathComponent(at index: Int) -> String? {
        guard pathComponents.indices.contains(index) else {
            return nil
        }
        return pathComponents[index]
    }

    func keyComponents(includingVariant: Bool = true) -> [String]? {
        guard let title = pathComponents.last?.precomposedStringWithCanonicalMapping else {
            assertionFailure("Can't create key components without a title")
            return nil
        }
        guard let host = host else {
            assertionFailure("Can't create key components without a host")
            return nil
        }
        guard let normalizedHost = host == "localhost" ? hostFromPathComponents : host else {
            assertionFailure("Can't create key components without a normalized host")
            return nil
        }

        if let pageResource = pageResource {
            return [normalizedHost, pageResource, title]
        } else if isImageURL, let imageName = imageName {
            if includingVariant, let imageWidth = imageWidth {
                return [normalizedHost, imageName, String(imageWidth)]
            } else {
                return [normalizedHost, imageName]
            }
        } else if isCSSResource {
            switch title {
            case "site": // site-specific
                return [normalizedHost, title, "css"]
            default: // global
                return [title, "css"]
            }
        } else if isJSResource { // global
            return [title, "js"]
        } else {
            return [normalizedHost, title]
        }
    }

    var hostFromPathComponents: String? {
        guard let firstPathComponent = pathComponents.first else {
            return nil
        }
        if firstPathComponent == "/" {
            return pathComponent(at: 1)
        } else {
            return firstPathComponent
        }
    }

    var isPageResource: Bool {
        return pathComponent(at: pathComponents.indices.endIndex - 3) == "page"
    }

    var isCSSResource: Bool {
        return pathComponents.contains("css")
    }

    var isJSResource: Bool {
        return pathComponents.contains("javascript")
    }

    var pageResource: String? {
        guard isPageResource else {
            return nil
        }
        return pathComponent(at: pathComponents.indices.endIndex - 2)
    }

    var imageName: String? {
        guard isImageURL else {
            return nil
        }
        if let pxRange = lastPathComponent.range(of: "px-") {
            return String(lastPathComponent[pxRange.upperBound..<lastPathComponent.endIndex])
        } else {
            return lastPathComponent
        }
    }

    #warning("TODO: Update to use logic from WMFImageURLParsing")
    var imageWidth: UInt? {
        guard isImageURL else {
            return nil
        }
        guard pathComponents.contains("thumb") else {
            return nil
        }
        guard let pxRange = lastPathComponent.range(of: "px-") else {
            return nil
        }
        let width = lastPathComponent[..<pxRange.lowerBound]
        return UInt(width)
    }
}

extension URL {
    var isImageURL: Bool {
        return host == "upload.wikimedia.org"
    }
}

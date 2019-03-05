import Foundation
import CoreData

class ArticleCacheController: NSObject {
    static let articleCacheWasUpdatedNotification = Notification.Name("ArticleCachWasUpdated")
    private let WMFExtendedFileAttributeNameMIMEType = "org.wikimedia.MIMEType"

    let dispatchQueue = DispatchQueue(label: "ArticleCacheControllerDispatchQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)

    let fetcher: ArticleFetcher
    let cacheURL: URL
    let fileManager = FileManager.default

    init(fetcher: ArticleFetcher) {
        guard
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        else {
            fatalError()
        }
        let documentsURL = URL(fileURLWithPath: documentsPath)
        cacheURL = documentsURL.appendingPathComponent("Article Cache", isDirectory: true)
        do {
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
            print("Created Article Cache directory: \(cacheURL)")
        } catch let error {
            fatalError(error.localizedDescription)
        }
        self.fetcher = fetcher
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.backgroundContext)
        NotificationCenter.default.addObserver(self, selector: #selector(viewContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.viewContext)
    }

    @objc private func backgroundContextDidSave(_ notification: NSNotification) {
        let context = viewContext
        context.performAndWait {
            self.save(moc: context)
        }
    }

    @objc private func viewContextDidSave(_ notification: NSNotification) {
        self.postArticleCacheUpdatedNotification()
    }

    private func postArticleCacheUpdatedNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil, userInfo: nil)
        }
    }

    func removeCachedArticle(with articleURL: URL) {
        let context = backgroundContext
        dispatchQueue.async(flags: .barrier) {
            context.perform {
                self.fetcher.cancelAllTasks(forGroupWithKey: articleURL.key)
                guard let group = self.cacheGroup(for: articleURL, in: context) else {
                    assertionFailure("Cache group for \(articleURL) doesn't exist")
                    return
                }
                guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                    assertionFailure("Cache group for \(articleURL) has no cache items")
                    return
                }
                for cacheItem in cacheItems where cacheItem.cacheGroups?.count == 1 {
                    let key = cacheItem.key
                    guard let pathComponent = key?.sha256() ?? key else {
                        assertionFailure("cacheItem has no key")
                        continue
                    }
                    let cachedFileURL = self.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
                    do {
                        try self.fileManager.removeItem(at: cachedFileURL)
                        context.delete(cacheItem)
                    } catch let error as NSError {
                        if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                            context.delete(cacheItem)
                        } else {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
                context.delete(group)
                self.save(moc: context)
            }
        }
    }

    private func fileURL(for url: URL, includingVariantIfAvailable: Bool = true) -> URL? {
        let key = CacheItem.key(for: url, includingVariantIfAvailable: includingVariantIfAvailable)
        let pathComponent = key.sha256() ?? key
        return cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
    }

    func isCached(_ articleURL: URL) -> Bool {
        assert(Thread.isMainThread)
        return cacheGroup(for: articleURL, in: viewContext) != nil
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Cache")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        return container
    }()


    // MARK: Background context - write only

    private lazy var backgroundContext: NSManagedObjectContext = {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = viewContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return backgroundContext
    }()


    // MARK: View context - read only

    private lazy var viewContext: NSManagedObjectContext = {
        let viewContext = persistentContainer.viewContext
        return viewContext
    }()

    // MARK: Cache groups

    private func cacheGroup(for articleURL: URL, in moc: NSManagedObjectContext) -> CacheGroup? {
        let key = CacheGroup.key(for: articleURL)
        return cacheGroup(with: key, in: moc)
    }

    private func cacheGroup(with key: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        let fetchRequest: NSFetchRequest<CacheGroup> = CacheGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        fetchRequest.fetchLimit = 1
        do {
            guard let group = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return group
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    private func createCacheGroup(with key: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheGroup", in: moc) else {
            return nil
        }
        let group = CacheGroup(entity: entity, insertInto: moc)
        group.key = key
        print("ArticleCacheController: Created cache group with key: \(key)")
        return group
    }

    private func createCacheItem(with key: String, in moc: NSManagedObjectContext) -> CacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheItem", in: moc) else {
            return nil
        }
        let item = CacheItem(entity: entity, insertInto: moc)
        item.key = key
        item.date = NSDate()
        print("ArticleCacheController: Created cache item with key: \(key)")
        return item
    }

    // MARK: Cache items

    private func cacheItem(with key: String, in moc: NSManagedObjectContext) -> CacheItem? {
        let fetchRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        fetchRequest.fetchLimit = 1
        do {
            guard let item = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return item
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: Fetch or create

    func fetchOrCreateCacheGroup(with key: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        return cacheGroup(with: key, in: moc) ?? createCacheGroup(with: key, in: moc)
    }

    func fetchOrCreateCacheItem(with key: String, in moc: NSManagedObjectContext) -> CacheItem? {
        return cacheItem(with: key, in: moc) ?? createCacheItem(with: key, in: moc)
    }

    // MARK: Saving context

    private func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            fatalError("Error saving cache moc: \(error)")
        }
    }

    // Media: Article resources

    func toggleCache(for articleURL: URL) {
        assert(Thread.isMainThread)
        print("ArticlesController: toggled cache for \(articleURL)")
        if isCached(articleURL) {
            print("ArticlesController: cache for \(articleURL) exists, removing")
            removeCachedArticle(with: articleURL)
        } else {
            print("ArticlesController: cache for \(articleURL) doesn't exist, fetching")
            cacheResource(.mobileHTML, for: articleURL)
            cacheResource(.references, for: articleURL)
            cacheResource(.sections, for: articleURL)
            cacheMedia(for: articleURL)
            cacheData(for: articleURL)
        }
    }

    #warning("TODO: Check if file/cache item exists before downloading")
    func cacheResource(_ resource: Configuration.MobileAppsServices.Page.Resource, for articleURL: URL) {
        fetcher.downloadResource(resource, for: articleURL) { error, resourceURL, temporaryFileURL, mimeType in
            if let error = error {
                print("Failed to download resource for \(articleURL); \(error.localizedDescription)")
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                assertionFailure("Failed to download the contents of \(articleURL)")
                return
            }

            guard let resourceURL = resourceURL else {
                assertionFailure("Failed to get resourceURL needed to construct cache item key")
                return
            }

            var createItem = true
            let key = CacheItem.key(for: resourceURL)

            self.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { result in
                switch result {
                case .error(_):
                    createItem = false
                default:
                    break
                }
            }

            let context = self.backgroundContext
            context.perform {
                guard createItem else {
                    return
                }
                guard let group = self.fetchOrCreateCacheGroup(with: CacheGroup.key(for: articleURL), in: context) else {
                    return
                }

                guard let item = self.fetchOrCreateCacheItem(with: key, in: context) else {
                    return
                }
                group.addToCacheItems(item)
                self.save(moc: context)
            }
        }
    }

    // MARK: Moving files

    private enum FileMoveResult {
        case exists
        case success
        case error(Error)
    }

    private func moveFile(from fileURL: URL, toNewFileWithKey key: String, mimeType: String?, completion: @escaping (FileMoveResult) -> Void) {
        do {
            let pathComponent = key.sha256() ?? key
            let newFileURL = cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
            try self.fileManager.moveItem(at: fileURL, to: newFileURL)
            if let mimeType = mimeType {
                fileManager.setValue(mimeType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: newFileURL.path)
            }
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                print("Error moving file: \(error.localizedDescription)")
                completion(.error(error))
            }
        } catch let error {
            print("Error moving file: \(error.localizedDescription)")
            completion(.error(error))
        }
    }

    // MARK: Media

    func cacheMedia(for articleURL: URL) {
        fetcher.getMedia(for: articleURL) { error, media in
            if let error = error {
                print("ArticleCacheController: Failed to get media for \(articleURL) because of \(error.localizedDescription)")
                return
            }
            guard
                let items = media?.items,
                !items.isEmpty
            else {
                return
            }
            let context = self.backgroundContext
            context.perform {
                for item in items {
                    if let original = item.original {
                        self.cacheImage(original, for: articleURL, in: context)
                    }
                    if let thumbnail = item.thumbnail {
                        self.cacheImage(thumbnail, for: articleURL, in: context)
                    }
                }
            }
        }
    }

    private func cacheImage(_ image: ArticleFetcher.Media.Item.Image, for articleURL: URL, in context: NSManagedObjectContext) {
        guard
            let source = image.source,
            let url = URL(string: source),
            let group = self.fetchOrCreateCacheGroup(with: CacheGroup.key(for: articleURL), in: context)
        else {
            return
        }

        let key = CacheItem.key(for: url)

        if let cacheItem = cacheItem(with: key, in: context) {
            group.addToCacheItems(cacheItem)
            save(moc: context)
        } else {
            self.fetcher.downloadImage(url, forArticleWithURL: articleURL) { error, _, temporaryFileURL, mimeType in
                guard let temporaryFileURL = temporaryFileURL else {
                    return
                }

                var createItem = true

                self.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { result in
                    switch result {
                    case .error(let error):
                        createItem = false
                        print("Error moving file: \(error.localizedDescription)")
                    default:
                        break
                    }
                }

                guard createItem else {
                    return
                }
                guard let item = self.fetchOrCreateCacheItem(with: key, in: context) else {
                    return
                }

                group.addToCacheItems(item)
                self.save(moc: context)
            }
        }
    }

    // MARK: CSS & JS (Update when real endpoints are available)

    #warning("TODO: Check if files/cache items exist before downloading")
    func cacheData(for articleURL: URL) {
        for data in ArticleFetcher.Data.allCases {
            fetcher.downloadData(data, for: articleURL) { error, cssURL, temporaryFileURL, mimeType in
                self.handleDataDownloadCompletion(articleURL: articleURL, error: error, cssURL: cssURL, temporaryFileURL: temporaryFileURL, mimeType: mimeType)
            }
        }
    }

    private func handleDataDownloadCompletion(articleURL: URL, error: Error?, cssURL: URL?, temporaryFileURL: URL?, mimeType: String?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let cssURL = cssURL else {
            assertionFailure("No cssURL; won't be able to construct cache key")
            return
        }
        guard let temporaryFileURL = temporaryFileURL else {
            return
        }

        var createItem = true
        let key = CacheItem.key(for: cssURL)

        self.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { result in
            switch result {
            case .error(_):
                createItem = false
            default:
                break
            }
        }

        let context = self.backgroundContext
        context.perform {
            guard createItem else {
                return
            }
            guard let group = self.fetchOrCreateCacheGroup(with: CacheGroup.key(for: articleURL), in: context) else {
                return
            }

            guard let item = self.fetchOrCreateCacheItem(with: key, in: context) else {
                return
            }
            group.addToCacheItems(item)
            self.save(moc: context)
        }
    }
}

extension ArticleCacheController: PermanentlyPersistableURLCacheDelegate {
    func permanentlyPersistedResponse(for url: URL) -> CachedURLResponse? {
        assert(!Thread.isMainThread)
        if let cachedFilePath = fileURL(for: url)?.path, let data = fileManager.contents(atPath: cachedFilePath) {
            return cachedURLResponse(for: url, with: data, at: cachedFilePath)
        } else if url.isImageURL, let cachedFilePath = fileURL(for: url, includingVariantIfAvailable: false)?.path, let data = fileManager.contents(atPath: cachedFilePath) {
            return cachedURLResponse(for: url, with: data, at: cachedFilePath)
        } else {
            return nil
        }
    }

    private func cachedURLResponse(for url: URL, with data: Data, at filePath: String) -> CachedURLResponse {
        let mimeType = fileManager.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath)
        let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
        return CachedURLResponse(response: response, data: data)
    }
}

private extension FileManager {
    func setValue(_ value: String, forExtendedFileAttributeNamed attributeName: String, forFileAtPath path: String) {
        let attributeNamePointer = (attributeName as NSString).utf8String
        let pathPointer = (path as NSString).fileSystemRepresentation
        let valuePointer = (value as NSString).utf8String

        let result = setxattr(pathPointer, attributeNamePointer, valuePointer, strlen(valuePointer), 0, 0)
        assert(result != -1)
    }

    func getValueForExtendedFileAttributeNamed(_ attributeName: String, forFileAtPath path: String) -> String? {
        let name = (attributeName as NSString).utf8String
        let path = (path as NSString).fileSystemRepresentation

        let bufferLength = getxattr(path, name, nil, 0, 0, 0)

        guard bufferLength != -1, let buffer = malloc(bufferLength) else {
            return nil
        }

        let readLen = getxattr(path, name, buffer, bufferLength, 0, 0)
        return String(bytesNoCopy: buffer, length: readLen, encoding: .utf8, freeWhenDone: true)
    }
}

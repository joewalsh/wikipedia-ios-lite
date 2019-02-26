import Foundation
import CoreData

class ArticleCacheController: NSObject {
    static let articleCacheWasUpdatedNotification = Notification.Name("ArticleCachWasUpdated")

    let dispatchQueue = DispatchQueue(label: "ArticleCacheControllerDispatchQueue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)

    let cacheURL: URL
    let fileManager = FileManager.default

    override init() {
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
                guard let group = self.cacheGroup(for: articleURL, in: context) else {
                    assertionFailure("Cache group for \(articleURL) doesn't exist")
                    return
                }
                guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                    assertionFailure("Cache group for \(articleURL) has no cache items")
                    return
                }
                for cacheItem in cacheItems {
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
                        if error.code == NSFileWriteFileExistsError {
                            return
                        } else {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
                // TODO: check if items were really deleted
                context.delete(group)
                self.save(moc: context)
            }
        }
    }

    private func filePath(for url: URL) -> String? {
        return fileURL(for: url)?.path
    }

    private func fileURL(for url: URL) -> URL? {
        let key = CacheItem.key(for: url)
        let pathComponent = key.sha256() ?? key
        return cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
    }

    func isCached(_ articleURL: URL) -> Bool {
        assert(Thread.isMainThread)
        let isCached = cacheGroup(for: articleURL, in: viewContext) != nil
        return isCached
    }

    func moveTemporaryFileToCache(temporaryFileURL: URL, withContentsOf url: URL, completion: @escaping (Error?, String) -> Void) {
        assert(!Thread.isMainThread)
        let key = CacheItem.key(for: url)
        do {
            let keyHash = key.sha256()
            let newFileURL = cacheURL.appendingPathComponent(keyHash ?? key, isDirectory: false)
            try fileManager.moveItem(at: temporaryFileURL, to: newFileURL)
            completion(nil, key) // hashed key is only for files, core data uses regular keys
        } catch let error {
            completion(error, key)
            fatalError(error.localizedDescription)
        }
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

    // write only
    private lazy var backgroundContext: NSManagedObjectContext = {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = viewContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return backgroundContext
    }()

    // read only
    private lazy var viewContext: NSManagedObjectContext = {
        let viewContext = persistentContainer.viewContext
        return viewContext
    }()

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

    private func allCacheGroups(in moc: NSManagedObjectContext) -> [CacheGroup] {
        let fetchRequest: NSFetchRequest<CacheGroup> = CacheGroup.fetchRequest()
        do {
            return try moc.fetch(fetchRequest)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    private func cacheGroup(for articleURL: URL, in moc: NSManagedObjectContext) -> CacheGroup? {
        let key = CacheGroup.key(for: articleURL)
        return cacheGroup(with: key, in: moc)
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

    enum Result {
        case alreadyCached
        case needsFetch
    }

    func updateCacheGroup(for articleURL: URL, completion: @escaping (Result) -> Void) {
        let context = backgroundContext
        context.perform {
            completion(.needsFetch)
        }
    }

    func addCacheItemToCacheGroup(for articleURL: URL, cacheItemKey: String) {
        let context = backgroundContext
        context.perform {
            let cacheGroupKey = CacheGroup.key(for: articleURL)
            guard
                let group = self.fetchOrCreateCacheGroup(with: cacheGroupKey, in: context),
                let item = self.fetchOrCreateCacheItem(with: cacheItemKey, in: context)
            else {
                return
            }
            group.addToCacheItems(item)
            self.save(moc: context)
        }
    }

    func fetchOrCreateCacheGroup(with key: String, in moc: NSManagedObjectContext) -> CacheGroup? {
        return cacheGroup(with: key, in: moc) ?? createCacheGroup(with: key, in: moc)
    }

    func fetchOrCreateCacheItem(with key: String, in moc: NSManagedObjectContext) -> CacheItem? {
        return cacheItem(with: key, in: moc) ?? createCacheItem(with: key, in: moc)
    }

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

    // MARK: Media

    func cacheMedia(_ media: ArticleFetcher.Media, for articleURL: URL, completion: @escaping (URL?, String?) -> Void) {
        guard let items = media.items, !items.isEmpty else {
            print("No images to cache for \(articleURL), returning")
            completion(nil, nil)
            return
        }
        let context = backgroundContext
        context.perform {
            let key = CacheGroup.key(for: articleURL)
            guard let group = self.fetchOrCreateCacheGroup(with: key, in: context) else {
                assertionFailure("Couldn't fetch or create cache group for \(articleURL)")
                completion(nil, nil)
                return
            }

            for item in items {
                if let (url, key) = self.cacheImage(item.original, with: item.titles, group: group, in: context) {
                    completion(url, key)
                }
                if let (url, key) = self.cacheImage(item.thumbnail, with: item.titles, group: group, in: context) {
                    completion(url, key)
                }
            }
            self.save(moc: context)
        }
    }

    private func cacheImage(_ image: ArticleFetcher.Media.Item.Image?, with titles: ArticleFetcher.Media.Item.Titles?, group: CacheGroup, in moc: NSManagedObjectContext) -> (URL, String)? {
        guard
            let image = image,
            let source = image.source,
            let url = URL(string: source),
            let host = url.host
        else {
            assertionFailure("Couldn't cache image; image is nil or some properties are missing")
            return nil
        }

        let name = titles?.canonical ?? titles?.normalized ?? url.lastPathComponent

        let key: String
        if let width = image.width {
            key = "\(host)__media__\(name)__\(width)"
        } else {
            key = "\(host)__media_\(name)"
        }

        let item = self.fetchOrCreateCacheItem(with: key, in: moc)
        item?.addToCacheGroups(group)

        return (url, key)
    }
}

extension ArticleCacheController: PermanentlyPersistableURLCacheDelegate {
    func permanentlyPersistedData(for url: URL) -> Data? {
        assert(!Thread.isMainThread)
        guard let cachedFilePath = fileURL(for: url)?.path else {
            return nil
        }
        return fileManager.contents(atPath: cachedFilePath)
    }
}

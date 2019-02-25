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
        dispatchQueue.async(flags: .barrier) {
            guard let cachedFileURL = self.fileURL(for: articleURL) else {
                return
            }
            do {
                try self.fileManager.removeItem(at: cachedFileURL)
            } catch let error as NSError {
                if error.code == NSFileWriteFileExistsError {
                    return
                } else { fatalError(error.localizedDescription) }
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

    func moveArticleHTMLFileToCache(fileURL: URL, withContentsOf articleURL: URL) {
        assert(!Thread.isMainThread)
        do {
            let newFileURL = cacheFileURL(for: articleURL)
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            postArticleCacheUpdatedNotification(for: articleURL, cached: true)
        } catch let error {
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

    private lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
}

extension ArticleCacheController: PermanentlyPersistableURLCacheDelegate {
    func permanentlyPersistedData(for url: URL) -> Data? {
        assert(!Thread.isMainThread)
        let cachedFileURL = cacheFileURL(for: url)
        return fileManager.contents(atPath: cachedFileURL.path)
    }
}

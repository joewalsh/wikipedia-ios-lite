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
        } catch let error {
            fatalError(error.localizedDescription)
        }
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.backgroundContext)
        NotificationCenter.default.addObserver(self, selector: #selector(viewContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.viewContext)
    }

    private func postArticleCacheUpdatedNotification(for articleURL: URL, cached: Bool) {
        let userInfo: [String: Any] = [
            ArticleCacheController.articleCacheWasUpdatedArticleURLKey: articleURL,
            ArticleCacheController.articleCacheWasUpdatedIsCachedKey: cached
        ]
    @objc private func backgroundContextDidSave(_ notification: NSNotification) {
        let context = viewContext
        context.performAndWait {
            self.save(moc: context)
        }
    }

    @objc private func viewContextDidSave(_ notification: NSNotification) {
        self.postArticleCacheUpdatedNotification()
    }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ArticleCacheController.articleCacheWasUpdatedNotification, object: nil, userInfo: userInfo)
        }
    }

    func removeCachedArticleData(for articleURL: URL) {
        dispatchQueue.async(flags: .barrier) {
            let cachedFileURL = self.cacheFileURL(for: articleURL)
            do {
                try self.fileManager.removeItem(at: cachedFileURL)
                self.postArticleCacheUpdatedNotification(for: articleURL, cached: false)
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }
    }

    private func cacheKey(for url: URL) -> String {
        return url.path.replacingOccurrences(of: "/", with: "_")
    }

    private func cacheFilePath(for url: URL) -> String {
        return cacheFileURL(for: url).path
    }

    private func cacheFileURL(for url: URL) -> URL {
        let key = cacheKey(for: url)
        return cacheURL.appendingPathComponent(key, isDirectory: false)
    }

    func isCached(_ articleURL: URL) -> Bool {
        return fileManager.fileExists(atPath: cacheFilePath(for: articleURL))
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

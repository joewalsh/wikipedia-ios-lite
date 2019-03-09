import WebKit

final class TablesUserScript: UserScriptWithCompletion<() -> Void> {
    #warning("TablesUserScript must take an Article object with title, isMain")
    init(collapse: Bool, completion: Completion? = nil) {
        let messageHandlerName = "wmfTablesCollapsed"

        let isMain = false // should be coming from the outside
        let pageTitle = "Article Title" // should be coming from the outside
        let infoboxTitle = "Quick Facts"
        let otherTitle = "More information"
        let footerTitle = "Close"

        let source = """
        window.wmf.collapseTables(
        \(collapse.description),
        \(isMain.description),
        '\(pageTitle)',
        '\(infoboxTitle)',
        '\(otherTitle)',
        '\(footerTitle)', () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

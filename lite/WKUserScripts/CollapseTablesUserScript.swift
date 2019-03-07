import WebKit

final class CollapseTablesUserScript: UserScriptWithCompletion {
    init(collapseTables: Bool, completion: Completion? = nil) {
        let messageHandlerName = "wmfTablesCollapsed"
        let source = """
        wmf.collapseTables(\(collapseTables.description), () => {
        window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }
}

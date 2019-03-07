import WebKit

final class ThemeUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: Theme, completion: Completion? = nil) {
        let messageHandlerName = "wmfThemeApplied"
        let source = """
        window.wmf.setTheme('\(theme.kind.jsName)', () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({});
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

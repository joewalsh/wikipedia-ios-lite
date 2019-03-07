import WebKit

final class ThemeUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: Theme.Kind, completion: Completion? = nil) {
        let messageHandlerName = "wmfThemeApplied"
        let source = """
        window.wmf.setTheme('\(theme.jsName)', () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({});
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

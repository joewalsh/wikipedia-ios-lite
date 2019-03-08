import WebKit

final class ThemeUserScript: UserScriptWithCompletion<() -> Void> {
    static func source(with theme: Theme, messageHandlerName: String? = nil) -> String {
        let callback: String?
        if let messageHandlerName = messageHandlerName {
            callback = """
            window.requestAnimationFrame(() => {
                window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
            })
            """
        } else {
            callback = nil
        }

        let source: String
        if let callback = callback {
            source = """
            window.wmf.setTheme('\(theme.kind.jsName)', \(theme.dimImages.description), () => {
                \(callback)
            })
            """
        } else {
            source = """
            window.wmf.setTheme('\(theme.kind.jsName)', \(theme.dimImages.description))
            """
        }
        return source
    }

    init(theme: Theme, completion: Completion? = nil) {
        let messageHandlerName = "wmfThemeApplied"
        let source = ThemeUserScript.source(with: theme, messageHandlerName: messageHandlerName)
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

import WebKit

final class ThemeUserScript: UserScriptWithCompletion<() -> Void> {
    static func source(with theme: Theme, messageHandlerName: String? = nil) -> String {
        let callback: String?
        if let messageHandlerName = messageHandlerName {
            callback = """
            window.requestAnimationFrame(() => {
                window.webkit.messageHandlers.\(messageHandlerName).postMessage({});
            });
            """
        } else {
            callback = nil
        }

        var source: String = """
        pagelib.ThemeTransform.setTheme(document, pagelib.ThemeTransform.THEME.\(theme.kind.jsName));
        pagelib.DimImagesTransform.dim(window, \(theme.dimImages.description));
        """
        if let callback = callback {
            source += "\n\(callback)"
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

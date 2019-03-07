import WebKit

final class ThemeUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: UserDefaults.Theme, completion: Completion? = nil) {
        let messageHandlerName = "wmf.theme.applied"
        let source = """
        window.wmf.setTheme(\(theme.name), () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage();
        });
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }
}

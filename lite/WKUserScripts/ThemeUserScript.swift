import WebKit

final class ThemeUserScript: UserScriptWithCompletion {
    init(theme: UserDefaults.Theme, completion: Completion? = nil) {
        let messageHandlerName = "wmf.theme.applied"
        let source = """
        wmf.setTheme(\(theme.name), () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage();
        });
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }
}

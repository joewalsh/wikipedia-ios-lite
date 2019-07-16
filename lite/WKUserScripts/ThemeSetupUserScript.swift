import WebKit

final class ThemeSetupUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: Theme, completion: Completion? = nil) {
        let messageHandlerName = "quickTheme"
        let source = """
        document.firstElementChild.classList.add("pagelib_platform_ios")
        document.firstElementChild.classList.add("\(theme.kind.cssClass)")
        window.requestAnimationFrame(() => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
        })
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }
    
    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

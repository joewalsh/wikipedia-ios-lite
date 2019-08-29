import WebKit

final class ActionHandlerScript: WKUserScript   {
    static let messageHandlerName = "action"
    override init() {
        let source = """
        document.pcsActionHandler = (action) => {
            window.webkit.messageHandlers.\(ActionHandlerScript.messageHandlerName).postMessage(action)
        };
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

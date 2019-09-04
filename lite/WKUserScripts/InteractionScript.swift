import WebKit

final class ActionHandlerScript: WKUserScript   {
    static let messageHandlerName = "action"
    override init() {
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(ActionHandlerScript.messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = {
            theme: 'pagelib_theme_dark',
            loadImages: false,
            margins: { top: '16px', right: '16px', bottom: '16px', left: '16px' }
        };
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

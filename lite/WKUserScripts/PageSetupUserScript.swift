import WebKit

final class PageSetupUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: Theme, dimImages: Bool, expandTables: Bool, completion: Completion? = nil) {
        let messageHandlerName = "pageSetup"
        let source = """
        pagelib.c1.Page.setup({
        platform: pagelib.c1.Platforms.IOS,
        clientVersion: '\(WKUserScript.clientVersion)',
        l10n: {
            addTitleDescription: 'Titelbeschreibung bearbeiten',
            tableInfobox: 'Schnelle Fakten',
            tableOther: 'Weitere Informationen',
            tableClose: 'Schließen'
        },
        theme: pagelib.c1.Themes.\(theme.kind.jsName),
        dimImages: \(dimImages),
        margins: { top: '32px', right: '32px', bottom: '32px', left: '32px' },
        areTablesCollapsed: \(expandTables),
        scrollTop: 64
        }, () => {
            window.webkit.messageHandlers.\(messageHandlerName).postMessage({})
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}

import WebKit

final class PageSetupUserScript: UserScriptWithCompletion<() -> Void> {
    init(theme: Theme, dimImages: Bool, collapseTables: Bool, completion: Completion? = nil) {
        let messageHandlerName = "wmfPageSetup"

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let source = """
        pagelib.c1.PageMods.setMulti(document, {
        platform: pagelib.c1.Platforms.IOS,
        clientVersion: '\(version)',
        l10n: {
            addTitleDescription: 'Titelbeschreibung bearbeiten',
            tableInfobox: 'Schnelle Fakten',
            tableOther: 'Weitere Informationen',
            tableClose: 'Schließen'
        },
        theme: pagelib.c1.Themes.\(theme.kind.jsName),
        dimImages: \(dimImages),
        margins: { top: '32px', right: '32px', bottom: '32px', left: '32px' },
        areTablesCollapsed: \(collapseTables),
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

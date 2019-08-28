import WebKit

final class FooterSetupUserScript: UserScriptWithCompletion<() -> Void> {
    init(articleTitle: String, completion: Completion? = nil) {
        let messageHandlerName = "wmfFooterSetup"
        let source = """
        pagelib.c1.Footer.add({
          platform: pagelib.c1.Platforms.IOS,
          clientVersion: \(WKUserScript.clientVersion),
          title: '\(articleTitle)',
          menuItems: [pagelib.c1.Footer.MenuItemType.languages, pagelib.c1.Footer.MenuItemType.lastEdited, pagelib.c1.Footer.MenuItemType.pageIssues, pagelib.c1.Footer.MenuItemType.disambiguation, pagelib.c1.Footer.MenuItemType.talkPage, pagelib.c1.Footer.MenuItemType.referenceList],
          l10n: {
            'readMoreHeading': 'Read more',
            'menuDisambiguationTitle': 'Similar pages',
            'menuLanguagesTitle': 'Available in 9 other languages',
            'menuHeading': 'About this article',
            'menuLastEditedSubtitle': 'Full edit history',
            'menuLastEditedTitle': 'Edited today',
            'licenseString': 'Content is available under $1 unless otherwise noted.',
            'menuTalkPageTitle': 'View talk page',
            'menuPageIssuesTitle': 'Page issues',
            'viewInBrowserString': 'View article in browser',
            'licenseSubstitutionString': 'CC BY-SA 3.0',
            'menuCoordinateTitle': 'View on a map',
            'menuReferenceListTitle': 'References'
          },
          readMore: {
            itemCount: 3,
            baseURL: 'https://en.wikipedia.org/api/rest_v1'
          }
        })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        completion?()
    }
}


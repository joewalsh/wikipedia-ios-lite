import WebKit

final class InteractionSetupUserScript: UserScriptWithCompletion<(Interaction) -> Void> {
    init(completion: Completion? = nil) {
        let messageHandlerName = "interaction"
        let source = """
        pagelib.c1.InteractionHandling.setInteractionHandler((interaction) => { window.webkit.messageHandlers.\(messageHandlerName).postMessage(interaction) })
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true, messageHandlerName: messageHandlerName, completion: completion)
    }

    override func handleCompletion(receivedMessage message: WKScriptMessage) {
        guard
            let body = message.body as? [String: Any],
            let actionRawValue = body[Interaction.Keys.action] as? String,
            let action = Interaction.Action(rawValue: actionRawValue),
            let data = body[Interaction.Keys.data] as? [String: Any]
        else {
            assertionFailure("Acion or data is missing; data might be optional")
            return
        }
        let interaction = Interaction(action: action, data: data)
        completion?(interaction)
    }
}

struct Interaction {
    let action: Action
    let data: [String: Any]

    enum Action: String {
        case linkClicked = "link_clicked"
        case referenceClicked = "reference_clicked"
        case imageClicked = "image_clicked"
        case editSection = "edit_section"
        case addTitleDescription = "add_title_description"

        case footerItemSelected = "footer_item_selected"
        case saveOtherPage = "save_other_page"
        case readMoreTitlesRetrieved = "read_more_titles_retrieved"
        case viewLicense = "view_license"
        case viewInBrowser = "view_in_browser"
    }
}

fileprivate extension Interaction {
    struct Keys {
        static let action = "action"
        static let data = "data"
    }
}

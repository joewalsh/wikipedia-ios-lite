import WebKit

public class UserScriptWithCompletion<C>: WKUserScript, NamedScriptMessageHandler {
    typealias Completion = C
    let completion: Completion?
    public let messageHandlerName: String?

    init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool, messageHandlerName: String?, completion: Completion?) {
        self.messageHandlerName = messageHandlerName
        self.completion = completion
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard completion != nil else {
            return
        }
        DispatchQueue.main.async {
            self.handleCompletion(receivedMessage: message)
        }
    }

    open func handleCompletion(receivedMessage message: WKScriptMessage) {
        assertionFailure("Subclassers should override")
    }
}

public extension WKUserContentController {
    func addAndHandle<Completion>(_ userScriptWithCompletion: UserScriptWithCompletion<Completion>) {
        addUserScript(userScriptWithCompletion)
        guard
            userScriptWithCompletion.completion != nil,
            let messageHandlerName = userScriptWithCompletion.messageHandlerName
        else {
            return
        }
        add(userScriptWithCompletion, name: messageHandlerName)
    }
}

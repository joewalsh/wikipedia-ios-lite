import WebKit

public class UserScriptWithCompletion: WKUserScript {
    typealias Completion = (() -> Void)
    let completion: Completion?
    public let messageHandlerName: String?

    init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool, messageHandlerName: String?, completion: Completion?) {
        self.messageHandlerName = messageHandlerName
        self.completion = completion
        super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }
}

extension UserScriptWithCompletion: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let completion = completion else {
            return
        }
        DispatchQueue.main.async {
            completion()
        }
    }
}

public extension WKUserContentController {
    func addAndHandle(_ userScriptWithCompletion: UserScriptWithCompletion) {
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

import WebKit

public protocol NamedScriptMessageHandler: WKScriptMessageHandler {
    var messageHandlerName: String? { get }
}

import WebKit

class ThemeUserScript: WKUserScript {
    init(theme: String = "BLACK") {
        let source = """
        wmf.setTheme(\(theme))
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

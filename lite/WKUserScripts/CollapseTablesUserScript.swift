import WebKit

class CollapseTablesUserScript: WKUserScript {
    init(collapseTables: Bool) {
        let source = """
        wmf.collapseTables(\(collapseTables.description))
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

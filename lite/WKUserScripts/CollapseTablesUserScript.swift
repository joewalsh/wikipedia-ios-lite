import WebKit

class CollapseTablesUserScript: WKUserScript {
    init(collapseTables: Bool) {
        let source = """
        wmf.collapseTables(`\(collapseTables)`)
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

import XCTest
import WebKit

class UncachedArticleLoadingPerformanceTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        URLCache.shared.removeAllCachedResponses()
        app.launch()
    }

    func testArticleLoadPerformanceWihBaseline() {
        let openArticle = {
            let articleCell = self.app.tables.cells["article"].firstMatch
            articleCell.tap()
            self.startMeasuring()
            let element = self.app.webViews.firstMatch
            self.waitForElementToAppear(element: element) {
                self.stopMeasuring()
            }
        }
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            if app.tables.count == 1 {
                openArticle()
            } else if app.webViews.count == 1 {
                let closeButton = app.buttons["close"]
                closeButton.tap()
                openArticle()
            }
        }
    }


    func testArticleLoadWithoutBaseline() {
        let articleCell = app.tables.cells["article"].firstMatch
        articleCell.tap()
        let start = Date()
        let element = app.webViews.firstMatch
        waitForElementToAppear(element: element) {
            print("Elapsed: \(abs(start.timeIntervalSinceNow))")
        }
    }

    func waitForElementToAppear(element: XCUIElement, timeout: TimeInterval = 5, file: String = #file, line: UInt = #line, success: @escaping () -> Void) {
        let existsPredicate = NSPredicate(format: "exists == true")

        expectation(for: existsPredicate, evaluatedWith: element)

        waitForExpectations(timeout: timeout) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: true)
            } else {
                success()
            }
        }
    }

}

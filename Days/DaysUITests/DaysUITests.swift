import XCTest

final class DaysUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testQuietScenarioShowsQuietCard() throws {
        let app = makeApp(scenario: "quiet")

        app.launch()

        XCTAssertTrue(app.staticTexts["quiet.title"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["첫 방문을 기억했습니다."].exists)
    }

    @MainActor
    func testTimelineScenarioShowsHeadlineAndNoteField() throws {
        let app = makeApp(scenario: "timeline")

        app.launch()

        XCTAssertTrue(app.staticTexts["timeline.headline"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["note.input"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["note.save"].exists)
    }

    @MainActor
    func testErrorScenarioShowsRetryAction() throws {
        let app = makeApp(scenario: "error")

        app.launch()

        XCTAssertTrue(app.staticTexts["error.title"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["error.retry"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = makeApp(scenario: "quiet")
            app.launch()
        }
    }

    private func makeApp(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-days-ui-testing",
            "-days-scenario", scenario
        ]
        return app
    }
}

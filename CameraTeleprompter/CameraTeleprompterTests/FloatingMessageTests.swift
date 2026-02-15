import XCTest
@testable import CameraTeleprompter

final class FloatingMessageTests: XCTestCase {

    // MARK: - Severity → Color mapping

    func testPositiveSeverityIsGreen() {
        let color = FloatingMessageView.color(for: .positive)
        XCTAssertEqual(color, .green)
    }

    func testWarningSeverityIsOrange() {
        let color = FloatingMessageView.color(for: .warning)
        XCTAssertEqual(color, .orange)
    }

    func testAlertSeverityIsRed() {
        let color = FloatingMessageView.color(for: .alert)
        XCTAssertEqual(color, .red)
    }

    func testInfoSeverityIsWhite() {
        let color = FloatingMessageView.color(for: .info)
        XCTAssertEqual(color, .white)
    }

    // MARK: - Message formatting per event type

    func testFillerWordMessage() {
        let event = CoachingEvent(type: .fillerWord("um"), message: "\"um\"", severity: .warning)
        XCTAssertEqual(event.message, "\"um\"")
    }

    func testHedgingMessage() {
        let event = CoachingEvent(type: .hedging("maybe"), message: "\"maybe\"", severity: .warning)
        XCTAssertEqual(event.message, "\"maybe\"")
    }

    func testRunOnMessage() {
        let event = CoachingEvent(type: .runOn, message: "Long sentence", severity: .alert)
        XCTAssertEqual(event.message, "Long sentence")
    }

    func testGoodStreakMessage() {
        let event = CoachingEvent(type: .goodStreak, message: "Great flow!", severity: .positive)
        XCTAssertEqual(event.message, "Great flow!")
        XCTAssertEqual(FloatingMessageView.color(for: event.severity), .green)
    }

    func testPaceTooFastMessage() {
        let event = CoachingEvent(type: .paceTooFast, message: "Slow down", severity: .warning)
        XCTAssertEqual(event.message, "Slow down")
    }

    func testPaceTooSlowMessage() {
        let event = CoachingEvent(type: .paceTooSlow, message: "Pick up pace", severity: .info)
        XCTAssertEqual(event.message, "Pick up pace")
    }
}

import XCTest
@testable import CameraTeleprompter

final class CoachingStateTests: XCTestCase {

    var coachingState: CoachingState!

    override func setUp() {
        super.setUp()
        coachingState = CoachingState()
    }

    // MARK: - Initial state

    func testScoreStartsAt100() {
        XCTAssertEqual(coachingState.confidenceScore, 100)
    }

    func testHealthFractionStartsAt1() {
        XCTAssertEqual(coachingState.healthFraction, 1.0, accuracy: 0.001)
    }

    func testFillerCountStartsAtZero() {
        XCTAssertEqual(coachingState.fillerCount, 0)
    }

    func testWpmStartsAtZero() {
        XCTAssertEqual(coachingState.wpm, 0)
    }

    // MARK: - Filler deduction

    func testFillerDeductionAbove5PerMinute() {
        // fillerRate > 5 → deduct min(25, (rate - 5) * 3)
        // 8 fillers/min → (8-5)*3 = 9 points deducted
        coachingState.applyFillerRate(8.0)
        XCTAssertEqual(coachingState.confidenceScore, 91)
    }

    func testFillerDeductionCapsAt25() {
        // 20 fillers/min → (20-5)*3 = 45, capped at 25
        coachingState.applyFillerRate(20.0)
        XCTAssertEqual(coachingState.confidenceScore, 75)
    }

    func testNoFillerDeductionBelow5PerMinute() {
        coachingState.applyFillerRate(4.0)
        XCTAssertEqual(coachingState.confidenceScore, 100)
    }

    // MARK: - Hedging deduction

    func testHedgingDeductionAbove3PerMinute() {
        // hedgingRate > 3 → deduct min(20, (rate - 3) * 4)
        // 5 hedges/min → (5-3)*4 = 8 points deducted
        coachingState.applyHedgingRate(5.0)
        XCTAssertEqual(coachingState.confidenceScore, 92)
    }

    func testHedgingDeductionCapsAt20() {
        // 15 hedges/min → (15-3)*4 = 48, capped at 20
        coachingState.applyHedgingRate(15.0)
        XCTAssertEqual(coachingState.confidenceScore, 80)
    }

    // MARK: - Run-on deduction

    func testRunOnDeductionAbove20Percent() {
        // runOnRatio > 0.2 → deduct min(15, ratio * 30)
        // 50% run-on → 0.5 * 30 = 15
        coachingState.applyRunOnRatio(0.5)
        XCTAssertEqual(coachingState.confidenceScore, 85)
    }

    // MARK: - Pace deduction

    func testPaceDeductionTooSlow() {
        coachingState.applyPace(wpm: 80)
        XCTAssertEqual(coachingState.confidenceScore, 90)
    }

    func testPaceDeductionTooFast() {
        coachingState.applyPace(wpm: 200)
        XCTAssertEqual(coachingState.confidenceScore, 90)
    }

    func testNoPaceDeductionInRange() {
        coachingState.applyPace(wpm: 140)
        XCTAssertEqual(coachingState.confidenceScore, 100)
    }

    // MARK: - Health fraction

    func testHealthFractionMapsCorrectly() {
        coachingState.applyFillerRate(20.0) // -25
        // Score = 75, healthFraction = 75/100 = 0.75
        XCTAssertEqual(coachingState.healthFraction, 0.75, accuracy: 0.001)
    }

    func testHealthFractionNeverBelowZero() {
        // Stack all deductions
        coachingState.applyFillerRate(20.0)  // -25
        coachingState.applyHedgingRate(15.0) // -20
        coachingState.applyRunOnRatio(0.5)   // -15
        coachingState.applyPace(wpm: 80)     // -10
        // Total = -70, score = 30
        XCTAssertGreaterThanOrEqual(coachingState.healthFraction, 0.0)
        XCTAssertLessThanOrEqual(coachingState.healthFraction, 1.0)
    }

    // MARK: - Reset

    func testResetClearsAll() {
        coachingState.fillerCount = 10
        coachingState.wpm = 150
        coachingState.addEvent(CoachingEvent(type: .fillerWord("um"), message: "um", severity: .warning))
        coachingState.applyFillerRate(10.0)

        coachingState.reset()

        XCTAssertEqual(coachingState.confidenceScore, 100)
        XCTAssertEqual(coachingState.fillerCount, 0)
        XCTAssertEqual(coachingState.wpm, 0)
        XCTAssertTrue(coachingState.recentEvents.isEmpty)
        XCTAssertEqual(coachingState.healthFraction, 1.0, accuracy: 0.001)
    }

    // MARK: - Event cap

    func testEventCapAt20() {
        for i in 0..<25 {
            coachingState.addEvent(CoachingEvent(type: .fillerWord("um"), message: "um #\(i)", severity: .warning))
        }
        XCTAssertEqual(coachingState.recentEvents.count, 20)
    }
}

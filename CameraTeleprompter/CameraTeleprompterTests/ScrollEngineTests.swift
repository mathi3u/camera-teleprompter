import XCTest
@testable import CameraTeleprompter

final class ScrollEngineTests: XCTestCase {
    var engine: ScrollEngine!

    override func setUp() {
        super.setUp()
        engine = ScrollEngine()
        engine.contentHeight = 1000
        engine.viewportHeight = 200
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(engine.offset, 0)
        XCTAssertFalse(engine.isScrolling)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.speed, 60)
    }

    // MARK: - Start / Stop

    func testStartSetsScrolling() {
        engine.start()
        XCTAssertTrue(engine.isScrolling)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.offset, 0)
    }

    func testStopClearsState() {
        engine.start()
        simulateFrames(count: 10, fps: 60)
        engine.stop()
        XCTAssertFalse(engine.isScrolling)
        XCTAssertFalse(engine.isPaused)
    }

    // MARK: - Tick

    func testTickAdvancesOffset() {
        engine.start()
        // Simulate 1 second at 60fps => 60 frames
        simulateFrames(count: 60, fps: 60)
        // speed=60 pts/s, dt=1s => offset ~60
        XCTAssertEqual(engine.offset, 60, accuracy: 1.0)
    }

    func testTickDoesNotAdvanceWhenPaused() {
        engine.start()
        simulateFrames(count: 60, fps: 60) // ~60 pts
        let offsetBefore = engine.offset
        engine.pause()
        simulateFrames(count: 60, fps: 60, startTime: 1.0) // paused, no movement
        XCTAssertEqual(engine.offset, offsetBefore, accuracy: 0.01)
    }

    func testTickDoesNotAdvanceWhenNotScrolling() {
        engine.tick(now: 0)
        engine.tick(now: 0.016)
        XCTAssertEqual(engine.offset, 0)
    }

    func testTickResumesAfterPause() {
        engine.start()
        simulateFrames(count: 60, fps: 60) // ~60 pts
        engine.pause()
        simulateFrames(count: 60, fps: 60, startTime: 1.0) // paused
        engine.resume()
        simulateFrames(count: 60, fps: 60, startTime: 2.0) // ~60 more pts
        XCTAssertEqual(engine.offset, 120, accuracy: 2.0)
    }

    func testTickClampsToMaxOffset() {
        engine.contentHeight = 210
        engine.viewportHeight = 200
        // maxOffset = 10
        engine.start()
        simulateFrames(count: 120, fps: 60) // 2 seconds => 120 pts, but clamped to 10
        XCTAssertEqual(engine.offset, 10, accuracy: 0.01)
    }

    func testTickClampsDeltaTime() {
        engine.start()
        engine.tick(now: 0)
        engine.tick(now: 5) // dt=5, but clamped to 0.1 => 60 * 0.1 = 6
        XCTAssertEqual(engine.offset, 6, accuracy: 0.01)
    }

    // MARK: - Speed

    func testSetSpeedClampsMin() {
        engine.setSpeed(5)
        XCTAssertEqual(engine.speed, 10)
    }

    func testSetSpeedClampsMax() {
        engine.setSpeed(250)
        XCTAssertEqual(engine.speed, 200)
    }

    func testAdjustSpeed() {
        engine.adjustSpeed(by: 20)
        XCTAssertEqual(engine.speed, 80)
    }

    func testAdjustSpeedClampsDown() {
        engine.adjustSpeed(by: -100)
        XCTAssertEqual(engine.speed, 10)
    }

    // MARK: - Pause / Resume

    func testTogglePause() {
        engine.start()
        engine.togglePause()
        XCTAssertTrue(engine.isPaused)
        engine.togglePause()
        XCTAssertFalse(engine.isPaused)
    }

    func testPauseIgnoredWhenNotScrolling() {
        engine.pause()
        XCTAssertFalse(engine.isPaused)
    }

    // MARK: - Max Offset & End

    func testMaxOffsetCalculation() {
        engine.contentHeight = 500
        engine.viewportHeight = 200
        XCTAssertEqual(engine.maxOffset, 300)
    }

    func testMaxOffsetNeverNegative() {
        engine.contentHeight = 100
        engine.viewportHeight = 200
        XCTAssertEqual(engine.maxOffset, 0)
    }

    func testIsAtEnd() {
        engine.contentHeight = 210
        engine.viewportHeight = 200
        // maxOffset = 10
        engine.start()
        simulateFrames(count: 60, fps: 60) // 60 pts >> 10 maxOffset
        XCTAssertTrue(engine.isAtEnd)
    }

    func testIsNotAtEndInitially() {
        XCTAssertFalse(engine.isAtEnd)
    }

    // MARK: - Reset

    func testResetClearsOffset() {
        engine.start()
        simulateFrames(count: 60, fps: 60)
        engine.reset()
        XCTAssertEqual(engine.offset, 0)
    }

    // MARK: - Helpers

    /// Simulate `count` frames at given fps
    private func simulateFrames(count: Int, fps: Double, startTime: TimeInterval = 0) {
        let dt = 1.0 / fps
        for i in 0..<count {
            engine.tick(now: startTime + Double(i) * dt)
        }
    }
}

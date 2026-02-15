import XCTest
@testable import CameraTeleprompter

final class PitchDetectorTests: XCTestCase {

    // MARK: - Pitch detection

    func testSilenceBufferReturnsZero() {
        let buffer = [Float](repeating: 0, count: 2048)
        let pitch = PitchDetector.detectPitch(buffer: buffer, sampleRate: 44100)
        XCTAssertEqual(pitch, 0)
    }

    func testSyntheticSineWave440Hz() {
        let sampleRate: Float = 44100
        let frequency: Float = 440
        let count = 4096
        var buffer = [Float](repeating: 0, count: count)
        for i in 0..<count {
            buffer[i] = sin(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
        let detected = PitchDetector.detectPitch(buffer: buffer, sampleRate: sampleRate)
        // Allow some tolerance (within 5%)
        XCTAssertGreaterThan(detected, 418) // 440 * 0.95
        XCTAssertLessThan(detected, 462)    // 440 * 1.05
    }

    func testSyntheticSineWave200Hz() {
        let sampleRate: Float = 44100
        let frequency: Float = 200
        let count = 4096
        var buffer = [Float](repeating: 0, count: count)
        for i in 0..<count {
            buffer[i] = sin(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
        let detected = PitchDetector.detectPitch(buffer: buffer, sampleRate: sampleRate)
        XCTAssertGreaterThan(detected, 190)
        XCTAssertLessThan(detected, 210)
    }

    func testVeryQuietBufferReturnsZero() {
        let count = 2048
        var buffer = [Float](repeating: 0, count: count)
        // Very quiet signal (below 0.01 RMS threshold)
        for i in 0..<count {
            buffer[i] = 0.001 * sin(2.0 * .pi * 440 * Float(i) / 44100)
        }
        let pitch = PitchDetector.detectPitch(buffer: buffer, sampleRate: 44100)
        XCTAssertEqual(pitch, 0)
    }

    // MARK: - Uptalk detection

    func testUptalkDetectedWithRisingPitch() {
        let tracker = RealTimePitchTracker()
        // Simulate flat pitch then rising at sentence end
        // Feed several frames of stable pitch
        for _ in 0..<20 {
            tracker.addPitch(150)
        }
        // Signal sentence boundary and check rising pitch over last frames
        // Rising: last few readings are significantly higher
        for _ in 0..<5 {
            tracker.addPitch(180)
        }
        tracker.markSentenceEnd()

        XCTAssertGreaterThan(tracker.uptalkCount, 0)
    }

    func testNoUptalkWithFlatPitch() {
        let tracker = RealTimePitchTracker()
        for _ in 0..<25 {
            tracker.addPitch(150)
        }
        tracker.markSentenceEnd()

        XCTAssertEqual(tracker.uptalkCount, 0)
    }

    func testNoUptalkWithFallingPitch() {
        let tracker = RealTimePitchTracker()
        for _ in 0..<20 {
            tracker.addPitch(180)
        }
        for _ in 0..<5 {
            tracker.addPitch(140)
        }
        tracker.markSentenceEnd()

        XCTAssertEqual(tracker.uptalkCount, 0)
    }
}

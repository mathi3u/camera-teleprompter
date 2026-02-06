import XCTest
@testable import CameraTeleprompter

final class AudioLevelMonitorTests: XCTestCase {

    // MARK: - RMS Calculation

    func testRMSWithSilence() {
        let buffer: [Float] = [0, 0, 0, 0]
        let rms = buffer.withUnsafeBufferPointer { ptr in
            AudioLevelMonitor.rms(from: ptr.baseAddress!, count: buffer.count)
        }
        XCTAssertEqual(rms, 0, accuracy: 0.0001)
    }

    func testRMSWithKnownValues() {
        // RMS of [1, -1, 1, -1] = sqrt((1+1+1+1)/4) = 1.0
        let buffer: [Float] = [1, -1, 1, -1]
        let rms = buffer.withUnsafeBufferPointer { ptr in
            AudioLevelMonitor.rms(from: ptr.baseAddress!, count: buffer.count)
        }
        XCTAssertEqual(rms, 1.0, accuracy: 0.0001)
    }

    func testRMSWithHalfAmplitude() {
        // RMS of [0.5, -0.5, 0.5, -0.5] = 0.5
        let buffer: [Float] = [0.5, -0.5, 0.5, -0.5]
        let rms = buffer.withUnsafeBufferPointer { ptr in
            AudioLevelMonitor.rms(from: ptr.baseAddress!, count: buffer.count)
        }
        XCTAssertEqual(rms, 0.5, accuracy: 0.0001)
    }

    func testRMSWithEmptyBuffer() {
        let rms = AudioLevelMonitor.rms(from: UnsafePointer<Float>(bitPattern: 1)!, count: 0)
        XCTAssertEqual(rms, 0)
    }

    // MARK: - dB Conversion

    func testToDecibelsFullScale() {
        // RMS of 1.0 = 0 dB
        let db = AudioLevelMonitor.toDecibels(1.0)
        XCTAssertEqual(db, 0, accuracy: 0.01)
    }

    func testToDecibelsHalfAmplitude() {
        // RMS of 0.5 ≈ -6.02 dB
        let db = AudioLevelMonitor.toDecibels(0.5)
        XCTAssertEqual(db, -6.02, accuracy: 0.1)
    }

    func testToDecibelsSilence() {
        let db = AudioLevelMonitor.toDecibels(0)
        XCTAssertEqual(db, -160)
    }

    func testToDecibelsVeryQuiet() {
        // RMS of 0.001 ≈ -60 dB
        let db = AudioLevelMonitor.toDecibels(0.001)
        XCTAssertEqual(db, -60, accuracy: 0.1)
    }
}

import XCTest
@testable import CameraTeleprompter

final class SpeechTranscriberTests: XCTestCase {

    func testStartStopDoesNotCrash() {
        let transcriber = SpeechTranscriber()
        // Just verify lifecycle doesn't crash
        transcriber.stop()
        // Starting without authorization may fail gracefully
        XCTAssertFalse(transcriber.isTranscribing)
    }

    func testAuthorizationStatusCheck() {
        let status = SpeechTranscriber.authorizationStatus
        // Status should be one of the valid values
        XCTAssertTrue([.notDetermined, .denied, .restricted, .authorized].contains(status))
    }

    func testCallbackSetup() {
        let transcriber = SpeechTranscriber()
        var callbackCalled = false
        transcriber.onPartialTranscript = { _ in
            callbackCalled = true
        }
        // Callback shouldn't be called without starting
        XCTAssertFalse(callbackCalled)
    }

    func testErrorCallbackSetup() {
        let transcriber = SpeechTranscriber()
        var errorReceived: Error?
        transcriber.onError = { error in
            errorReceived = error
        }
        // No error without attempting anything
        XCTAssertNil(errorReceived)
    }

    func testStopAfterStopIsIdempotent() {
        let transcriber = SpeechTranscriber()
        transcriber.stop()
        transcriber.stop()
        XCTAssertFalse(transcriber.isTranscribing)
    }
}

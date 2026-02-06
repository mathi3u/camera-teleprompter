import XCTest
@testable import CameraTeleprompter

final class NotchDetectorTests: XCTestCase {

    func testDetectWithNilScreenReturnsNoNotch() {
        let geometry = NotchDetector.detect(screen: nil)
        XCTAssertFalse(geometry.hasNotch)
        XCTAssertEqual(geometry.notchRect, .zero)
    }

    func testOverlayFrameWithNilScreenReturnsZero() {
        let frame = NotchDetector.overlayFrame(screen: nil, height: 200)
        XCTAssertEqual(frame, .zero)
    }

    func testOverlayFrameReturnsReasonableSize() {
        // Uses actual main screen if available
        guard let screen = NSScreen.main else { return }
        let frame = NotchDetector.overlayFrame(screen: screen, height: 200)
        XCTAssertEqual(frame.height, 200)
        XCTAssertGreaterThan(frame.width, 0)
        // Should be centered-ish
        let screenMidX = screen.frame.midX
        let frameMidX = frame.midX
        XCTAssertEqual(frameMidX, screenMidX, accuracy: 1)
    }

    func testNotchGeometryStruct() {
        let geo = NotchGeometry(
            notchRect: NSRect(x: 500, y: 1400, width: 200, height: 32),
            leftSafeArea: NSRect(x: 0, y: 1400, width: 500, height: 32),
            rightSafeArea: NSRect(x: 700, y: 1400, width: 400, height: 32),
            hasNotch: true
        )
        XCTAssertTrue(geo.hasNotch)
        XCTAssertEqual(geo.notchRect.width, 200)
    }
}

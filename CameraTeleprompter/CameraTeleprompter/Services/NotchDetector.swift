import AppKit

struct NotchGeometry {
    let notchRect: NSRect
    let leftSafeArea: NSRect
    let rightSafeArea: NSRect
    let hasNotch: Bool
}

struct NotchDetector {
    /// Detect notch geometry on the given screen (defaults to main screen)
    static func detect(screen: NSScreen? = NSScreen.main) -> NotchGeometry {
        guard let screen else {
            return NotchGeometry(notchRect: .zero, leftSafeArea: .zero, rightSafeArea: .zero, hasNotch: false)
        }

        let safeAreaInsets = screen.safeAreaInsets
        let frame = screen.frame

        // Notch is present if there's a top safe area inset beyond the menu bar
        // On notched MacBooks, safeAreaInsets.top is ~32 (notch height)
        let hasNotch = safeAreaInsets.top > 0

        guard hasNotch else {
            return NotchGeometry(notchRect: .zero, leftSafeArea: .zero, rightSafeArea: .zero, hasNotch: false)
        }

        let notchHeight = safeAreaInsets.top
        // auxiliaryTopLeftArea and auxiliaryTopRightArea give us the areas flanking the notch
        guard let leftArea = screen.auxiliaryTopLeftArea,
              let rightArea = screen.auxiliaryTopRightArea else {
            return NotchGeometry(notchRect: .zero, leftSafeArea: .zero, rightSafeArea: .zero, hasNotch: false)
        }

        // The notch sits between the left and right auxiliary areas
        let notchX = leftArea.maxX
        let notchWidth = rightArea.minX - leftArea.maxX
        let notchY = frame.maxY - notchHeight // macOS bottom-left origin

        let notchRect = NSRect(x: notchX + frame.origin.x,
                               y: notchY,
                               width: notchWidth,
                               height: notchHeight)

        let leftSafeArea = NSRect(x: frame.origin.x,
                                  y: notchY,
                                  width: leftArea.width,
                                  height: notchHeight)

        let rightSafeArea = NSRect(x: rightArea.minX + frame.origin.x,
                                   y: notchY,
                                   width: rightArea.width,
                                   height: notchHeight)

        return NotchGeometry(
            notchRect: notchRect,
            leftSafeArea: leftSafeArea,
            rightSafeArea: rightSafeArea,
            hasNotch: hasNotch
        )
    }

    /// Get the recommended overlay frame for notch mode
    /// Places the overlay centered horizontally, just below the notch, spanning full width
    static func overlayFrame(screen: NSScreen? = NSScreen.main, height: CGFloat = 200) -> NSRect {
        guard let screen else { return .zero }

        let frame = screen.frame
        let safeAreaInsets = screen.safeAreaInsets
        let menuBarHeight = frame.height - screen.visibleFrame.height - safeAreaInsets.top

        // Position overlay just below the menu bar area
        let topY = frame.maxY - safeAreaInsets.top - menuBarHeight
        let overlayWidth = frame.width * 0.6
        let overlayX = frame.origin.x + (frame.width - overlayWidth) / 2

        return NSRect(x: overlayX, y: topY - height, width: overlayWidth, height: height)
    }
}

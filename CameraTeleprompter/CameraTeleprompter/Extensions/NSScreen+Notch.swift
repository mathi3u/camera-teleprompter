import AppKit

extension NSScreen {
    /// Whether this screen has a camera notch
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// The height of the notch area (0 if no notch)
    var notchHeight: CGFloat {
        safeAreaInsets.top
    }
}

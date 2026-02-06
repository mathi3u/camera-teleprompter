import AppKit

final class OverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Always on top
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        // Transparent & invisible to screen sharing
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false

        // Invisible to screen sharing (blocks legacy capture; ScreenCaptureKit may still see it)
        sharingType = .none

        // Click-through by default
        ignoresMouseEvents = true
    }

    // NSPanel normally won't become key; keep it that way for overlay mode
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

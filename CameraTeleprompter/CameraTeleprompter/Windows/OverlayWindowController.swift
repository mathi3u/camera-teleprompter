import AppKit
import SwiftUI

final class OverlayWindowController {
    private var panel: OverlayPanel?
    private let state: TeleprompterState

    init(state: TeleprompterState) {
        self.state = state
    }

    func show(mode: DisplayMode) {
        close()

        let frame: NSRect
        switch mode {
        case .notch:
            frame = NotchDetector.overlayFrame(height: 200)
        case .floating:
            // Default floating window: centered, 600x300
            guard let screen = NSScreen.main else { return }
            let screenFrame = screen.visibleFrame
            let width: CGFloat = 600
            let height: CGFloat = 300
            let x = screenFrame.midX - width / 2
            let y = screenFrame.midY - height / 2
            frame = NSRect(x: x, y: y, width: width, height: height)
        }

        let panel = OverlayPanel(contentRect: frame)

        if mode == .floating {
            // Floating mode: allow interaction, resizing, moving
            panel.ignoresMouseEvents = false
            panel.isMovableByWindowBackground = true
            panel.styleMask.insert(.resizable)
        }

        let contentView = OverlayContentView()
            .environment(state)

        panel.contentView = NSHostingView(rootView: contentView)
        panel.orderFrontRegardless()

        self.panel = panel
        state.isOverlayVisible = true
    }

    func close() {
        panel?.close()
        panel = nil
        state.isOverlayVisible = false
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }
}

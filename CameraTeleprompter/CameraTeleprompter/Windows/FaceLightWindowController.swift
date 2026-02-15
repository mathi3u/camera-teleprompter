import AppKit

/// Manages the face light panel lifecycle
final class FaceLightWindowController {
    private var panel: FaceLightPanel?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show(brightness: CGFloat = 0.8, thickness: CGFloat = 40, screen: NSScreen? = nil) {
        close()

        guard let targetScreen = screen ?? NSScreen.main else { return }

        let newPanel = FaceLightPanel(screen: targetScreen)
        newPanel.configure(brightness: brightness, thickness: thickness)
        newPanel.orderFrontRegardless()
        panel = newPanel
    }

    func updateSettings(brightness: CGFloat, thickness: CGFloat) {
        panel?.configure(brightness: brightness, thickness: thickness)
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}

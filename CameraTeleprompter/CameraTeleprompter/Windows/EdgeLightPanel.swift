import SwiftUI
import AppKit

// MARK: - SwiftUI Ring View

struct EdgeLightRingView: View {
    var brightness: CGFloat

    var body: some View {
        ZStack {
            // Outermost diffuse glow
            RoundedRectangle(cornerRadius: 80)
                .stroke(.white.opacity(brightness * 0.15), lineWidth: 120)
                .blur(radius: 60)

            // Mid glow
            RoundedRectangle(cornerRadius: 60)
                .stroke(.white.opacity(brightness * 0.35), lineWidth: 70)
                .blur(radius: 30)

            // Inner bright ring
            RoundedRectangle(cornerRadius: 45)
                .stroke(.white.opacity(brightness * 0.6), lineWidth: 35)
                .blur(radius: 12)

            // Core edge
            RoundedRectangle(cornerRadius: 35)
                .stroke(.white.opacity(brightness * 0.8), lineWidth: 10)
                .blur(radius: 4)
        }
        .padding(5)
    }
}

// MARK: - NSPanel

final class EdgeLightPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: true)

        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: EdgeLightRingView(brightness: 0.8))
        hostingView.frame = screen.frame
        contentView = hostingView
    }

    func updateBrightness(_ brightness: CGFloat) {
        let hostingView = NSHostingView(rootView: EdgeLightRingView(brightness: brightness))
        hostingView.frame = frame
        contentView = hostingView
    }
}

// MARK: - Controller

final class EdgeLightController {
    private var panel: EdgeLightPanel?

    func show(brightness: CGFloat = 0.8) {
        close()
        guard let targetScreen = NSScreen.main else { return }
        let newPanel = EdgeLightPanel(screen: targetScreen)
        newPanel.updateBrightness(brightness)
        newPanel.orderFrontRegardless()
        panel = newPanel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    var isVisible: Bool {
        panel != nil
    }
}

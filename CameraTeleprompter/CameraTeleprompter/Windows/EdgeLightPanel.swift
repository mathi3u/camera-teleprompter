import SwiftUI
import AppKit

// MARK: - SwiftUI Ring View

struct EdgeLightRingView: View {
    var brightness: CGFloat
    var mousePosition: CGPoint? // normalized 0...1 in screen space

    var body: some View {
        Canvas { context, size in
            // Draw glow ring using radial segments, dimming near mouse
            let rect = CGRect(origin: .zero, size: size)

            // Draw 4 layered rings
            let rings: [(opacity: CGFloat, lineWidth: CGFloat, blur: CGFloat, radius: CGFloat)] = [
                (0.20, 140, 70, 80),   // outermost diffuse
                (0.50, 80, 35, 60),    // mid glow
                (0.75, 40, 14, 45),    // inner bright
                (0.95, 12, 5, 35),     // core edge
            ]

            for ring in rings {
                var path = Path()
                path.addRoundedRect(in: rect.insetBy(dx: 5, dy: 5), cornerSize: CGSize(width: ring.radius, height: ring.radius))

                context.drawLayer { ctx in
                    ctx.addFilter(.blur(radius: ring.blur))
                    ctx.stroke(
                        path,
                        with: .color(.white.opacity(brightness * ring.opacity)),
                        lineWidth: ring.lineWidth
                    )
                }
            }
        }
        // Overlay a radial dim near mouse
        .overlay {
            if let mouse = mousePosition {
                RadialGradient(
                    colors: [.black.opacity(0.7), .clear],
                    center: UnitPoint(x: mouse.x, y: mouse.y),
                    startRadius: 0,
                    endRadius: 200
                )
                .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
    }
}

// MARK: - NSPanel

final class EdgeLightPanel: NSPanel {
    private var trackingTimer: Timer?
    private var hostingView: NSHostingView<EdgeLightRingView>?
    private var currentBrightness: CGFloat = 1.0

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

        let view = NSHostingView(rootView: EdgeLightRingView(brightness: 1.0, mousePosition: nil))
        view.frame = screen.frame
        contentView = view
        hostingView = view
    }

    func startMouseTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            self?.updateMousePosition()
        }
    }

    func stopMouseTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }

    private func updateMousePosition() {
        let mouseScreen = NSEvent.mouseLocation
        let screenFrame = frame
        // Normalize to 0...1
        let nx = (mouseScreen.x - screenFrame.minX) / screenFrame.width
        // Flip y (screen coords are bottom-up, SwiftUI is top-down)
        let ny = 1.0 - (mouseScreen.y - screenFrame.minY) / screenFrame.height
        let normalized = CGPoint(x: nx, y: ny)

        hostingView?.rootView = EdgeLightRingView(
            brightness: currentBrightness,
            mousePosition: normalized
        )
    }

    func updateBrightness(_ brightness: CGFloat) {
        currentBrightness = brightness
        hostingView?.rootView = EdgeLightRingView(
            brightness: brightness,
            mousePosition: nil
        )
    }
}

// MARK: - Controller

final class EdgeLightController {
    private var panel: EdgeLightPanel?

    func show(brightness: CGFloat = 1.0) {
        close()
        guard let targetScreen = NSScreen.main else { return }
        let newPanel = EdgeLightPanel(screen: targetScreen)
        newPanel.updateBrightness(brightness)
        newPanel.orderFrontRegardless()
        newPanel.startMouseTracking()
        panel = newPanel
    }

    func close() {
        panel?.stopMouseTracking()
        panel?.orderOut(nil)
        panel = nil
    }

    var isVisible: Bool {
        panel != nil
    }
}

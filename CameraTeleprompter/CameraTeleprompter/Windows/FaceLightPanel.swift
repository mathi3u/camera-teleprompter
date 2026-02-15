import AppKit

/// Full-screen borderless panel that draws a white ring for face lighting.
/// Sits at `.screenSaver` level and ignores mouse events (click-through).
final class FaceLightPanel: NSPanel {

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        setFrame(screen.frame, display: true)
    }

    func configure(brightness: CGFloat, thickness: CGFloat) {
        let ringView = FaceLightRingView(brightness: brightness, thickness: thickness)
        ringView.frame = contentView?.bounds ?? .zero
        ringView.autoresizingMask = [.width, .height]
        contentView?.subviews.forEach { $0.removeFromSuperview() }
        contentView?.addSubview(ringView)
    }
}

/// Custom NSView that draws a white ring around the screen edges
final class FaceLightRingView: NSView {
    var brightness: CGFloat
    var thickness: CGFloat

    init(brightness: CGFloat, thickness: CGFloat) {
        self.brightness = brightness
        self.thickness = thickness
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let color = NSColor.white.withAlphaComponent(brightness)
        context.setFillColor(color.cgColor)

        // Draw border ring (outer rect minus inner rect)
        let outer = bounds
        let inner = bounds.insetBy(dx: thickness, dy: thickness)

        context.addRect(outer)
        context.addRect(inner)
        context.fillPath(using: .evenOdd)
    }
}

import SwiftUI

struct TeleprompterScrollView: View {
    @Environment(TeleprompterState.self) private var state

    @State private var offset: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var timer: Timer?
    @State private var scrollMonitor: Any?
    @State private var startTime: Date?

    /// Maximum scroll offset - last line stays at bottom of viewport
    private var maxOffset: CGFloat {
        max(0, textHeight - viewportHeight)
    }

    /// Time-based speed multiplier: 1s pause, then ease to full speed over 2s
    private func speedMultiplier(elapsed: TimeInterval) -> CGFloat {
        let pause = 1.0
        let rampDuration = 2.0

        // First second: no movement
        guard elapsed > pause else { return 0 }

        // Next 2 seconds: ease from 0 to 1
        let t = min(1.0, (elapsed - pause) / rampDuration)
        // Smooth ease-in curve
        return CGFloat(t * t * (3 - 2 * t))
    }



    var body: some View {
        GeometryReader { geo in
            Text(state.currentScript.body)
                .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(width: geo.size.width - 24, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, viewportHeight * 0.4)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { textGeo in
                        Color.clear
                            .onAppear {
                                textHeight = textGeo.size.height
                                viewportHeight = geo.size.height
                            }
                    }
                )
                .offset(y: -offset)
                .onAppear {
                    viewportHeight = geo.size.height
                    startScrolling()
                    installScrollMonitor()
                }
                .onDisappear {
                    stopScrolling()
                    removeScrollMonitor()
                }
        }
        .clipped()
        .overlay(alignment: .top) {
            LinearGradient(colors: [.black.opacity(0.85), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 12)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 12)
                .allowsHitTesting(false)
        }
        .background(Color.black.opacity(0.85))
    }

    private func startScrolling() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard state.scrollEngine.isScrolling, !state.scrollEngine.isPaused else { return }

            // Apply arrow key nudges (skip ~3 lines per tap)
            if state.scrollNudge != 0 {
                let lineHeight = state.fontSize * 1.4
                offset += state.scrollNudge * lineHeight * 3
                state.scrollNudge = 0
            }

            let baseSpeed = state.scrollEngine.speed
            let elapsed = Date().timeIntervalSince(startTime ?? Date())

            // Time-based ramp at start, hard stop at end
            let startMul = speedMultiplier(elapsed: elapsed)
            offset += (baseSpeed * startMul) / 60.0

            // Clamp to valid range
            offset = max(0, offset)
            if maxOffset > 0 {
                offset = min(offset, maxOffset)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopScrolling() {
        timer?.invalidate()
        timer = nil
    }

    private func installScrollMonitor() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            let delta = event.scrollingDeltaY
            offset -= delta
            offset = max(0, offset)
            if maxOffset > 0 {
                offset = min(offset, maxOffset)
            }
            return nil
        }
    }

    private func removeScrollMonitor() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
    }
}

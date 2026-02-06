import SwiftUI

struct TeleprompterScrollView: View {
    @Environment(TeleprompterState.self) private var state

    @State private var offset: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var timer: Timer?
    @State private var scrollMonitor: Any?

    /// Maximum scroll offset - last line stays at bottom of viewport
    private var maxOffset: CGFloat {
        max(0, textHeight - viewportHeight)
    }

    /// Distance over which speed ramps up/down (half a viewport)
    private var rampDistance: CGFloat {
        max(state.fontSize * 1.4 * 3, viewportHeight * 0.5)
    }

    /// Smoothstep: S-curve from 0 to 1
    private func smoothstep(_ t: CGFloat) -> CGFloat {
        let c = max(0, min(1, t))
        return c * c * (3 - 2 * c)
    }

    /// Speed multiplier based on position: ease-in at start, ease-out at end
    private func speedMultiplier(at pos: CGFloat) -> CGFloat {
        guard maxOffset > 0 else { return 1.0 }

        // Ease-in: ramp up from start
        let startT = smoothstep(pos / rampDistance)

        // Ease-out: ramp down near end
        let endT = smoothstep((maxOffset - pos) / rampDistance)

        // Take the minimum (near start or near end, whichever is closer)
        let multiplier = min(startT, endT)

        // Never fully stop - minimum 5% speed so it always feels alive
        return max(0.05, multiplier)
    }

    var body: some View {
        GeometryReader { geo in
            Text(state.currentScript.body)
                .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(width: geo.size.width - 24, alignment: .leading)
                .padding(.horizontal, 12)
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard state.scrollEngine.isScrolling, !state.scrollEngine.isPaused else { return }

            // Apply arrow key nudges (skip ~3 lines per tap)
            if state.scrollNudge != 0 {
                let lineHeight = state.fontSize * 1.4
                offset += state.scrollNudge * lineHeight * 3
                state.scrollNudge = 0
            }

            // Apply eased speed: slow start, cruise, slow stop
            let baseSpeed = state.scrollEngine.speed
            let multiplier = speedMultiplier(at: offset)
            offset += (baseSpeed * multiplier) / 60.0

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

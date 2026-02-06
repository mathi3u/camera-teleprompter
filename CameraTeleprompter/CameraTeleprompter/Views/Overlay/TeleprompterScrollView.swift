import SwiftUI

struct TeleprompterScrollView: View {
    @Environment(TeleprompterState.self) private var state

    @State private var offset: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            Text(state.currentScript.body)
                .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(width: geo.size.width - 48)
                .padding(.horizontal, 24)
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
                }
                .onDisappear {
                    stopScrolling()
                }
        }
        .clipped()
        .overlay(alignment: .top) {
            LinearGradient(colors: [.black.opacity(0.85), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
                .allowsHitTesting(false)
        }
        .background(Color.black.opacity(0.85))
    }

    private func startScrolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard state.scrollEngine.isScrolling, !state.scrollEngine.isPaused else { return }
            let speed = state.scrollEngine.speed
            offset += speed / 60.0
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopScrolling() {
        timer?.invalidate()
        timer = nil
    }
}

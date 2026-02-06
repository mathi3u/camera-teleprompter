import SwiftUI

struct TeleprompterScrollView: View {
    @Environment(TeleprompterState.self) private var state

    @State private var textHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let engine = state.scrollEngine

            Text(state.currentScript.body)
                .font(.system(size: state.fontSize, weight: .medium))
                .foregroundStyle(state.textColor)
                .multilineTextAlignment(.center)
                .frame(width: geo.size.width - 32)
                .padding(.horizontal, 16)
                .background(
                    GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textHeight = textGeo.size.height
                            engine.contentHeight = textHeight
                            engine.viewportHeight = geo.size.height
                        }
                    }
                )
                .offset(y: geo.size.height - engine.offset)
        }
        .clipped()
        .overlay(alignment: .top) {
            // Fade gradient at top
            LinearGradient(colors: [.black.opacity(0.6), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 20)
        }
        .overlay(alignment: .bottom) {
            // Fade gradient at bottom
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 20)
        }
        .modifier(ScrollTickModifier(engine: state.scrollEngine))
    }
}

/// Drives the scroll engine tick from a TimelineView
struct ScrollTickModifier: ViewModifier {
    let engine: ScrollEngine

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !engine.isScrolling || engine.isPaused)) { timeline in
            content
                .onChange(of: timeline.date) { _, newDate in
                    engine.tick(now: newDate.timeIntervalSinceReferenceDate)
                }
        }
    }
}

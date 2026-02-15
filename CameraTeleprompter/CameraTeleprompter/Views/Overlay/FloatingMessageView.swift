import SwiftUI

struct FloatingMessageView: View {
    let event: CoachingEvent
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Text(event.message)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Self.color(for: event.severity))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    offset = -80
                    opacity = 0
                }
            }
    }

    static func color(for severity: CoachingEventSeverity) -> Color {
        switch severity {
        case .positive: .green
        case .info: .white
        case .warning: .orange
        case .alert: .red
        }
    }
}

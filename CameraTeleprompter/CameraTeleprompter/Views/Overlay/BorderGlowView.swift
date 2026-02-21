import SwiftUI

private let contentShape = UnevenRoundedRectangle(
    topLeadingRadius: 0, bottomLeadingRadius: 10,
    bottomTrailingRadius: 10, topTrailingRadius: 0
)

/// Applies outward glow on left, right, and bottom edges
struct OutwardGlowModifier: ViewModifier {
    @Environment(CoachingState.self) private var coachingState
    @State private var isPulsing = false
    var isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            let level = coachingState.audioLevel
            let boost = 0.3 + level * 0.7
            let color = activeGlowColor

            content
                // Opaque black behind content so shadows can't bleed through
                .background { contentShape.fill(.black) }
                // Outward glow on all sides
                .shadow(color: color.opacity(0.6 * boost), radius: 6 + level * 6)
                .shadow(color: color.opacity(0.4 * boost), radius: 16 + level * 12)
                .shadow(color: color.opacity(0.2 * boost), radius: 35 + level * 20)
                .shadow(color: color.opacity(0.1 * boost), radius: 60 + level * 30)
                .scaleEffect(isPulsing ? 1.01 : 1.0, anchor: .bottom)
                .animation(.easeOut(duration: 0.08), value: coachingState.audioLevel)
                .animation(.easeInOut(duration: 0.5), value: coachingState.flashSeverity == nil)
                .animation(.easeInOut(duration: 0.3), value: isPulsing)
                .onChange(of: coachingState.recentEvents.count) { _, _ in
                    guard let last = coachingState.recentEvents.last else { return }
                    switch last.severity {
                    case .warning, .alert:
                        isPulsing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            isPulsing = false
                        }
                    default:
                        break
                    }
                }
        } else {
            content
        }
    }

    private var activeGlowColor: Color {
        if let flash = coachingState.flashSeverity {
            switch flash {
            case .warning: return .orange
            case .alert: return .red
            case .positive: return .green
            case .info: return healthColor
            }
        }
        return healthColor
    }

    private var healthColor: Color {
        let h = coachingState.healthFraction
        if h < 0.5 {
            return Color(hue: Double(h) * 0.32, saturation: 0.9, brightness: 0.9)
        } else {
            return Color(hue: 0.16 + Double(h - 0.5) * 0.34, saturation: 0.9, brightness: 0.9)
        }
    }
}

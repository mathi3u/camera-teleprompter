import SwiftUI

struct BorderGlowView: View {
    @Environment(CoachingState.self) private var coachingState
    @State private var isPulsing = false

    private let cornerShape = UnevenRoundedRectangle(
        topLeadingRadius: 0, bottomLeadingRadius: 10,
        bottomTrailingRadius: 10, topTrailingRadius: 0
    )

    var body: some View {
        let level = coachingState.audioLevel
        let boost = 0.3 + level * 0.7
        let color = activeGlowColor

        ZStack {
            // Outer soft glow — expands with volume
            cornerShape
                .stroke(color.opacity(0.08 * boost), lineWidth: 20 + level * 30)
                .blur(radius: 12 + level * 10)

            // Mid glow
            cornerShape
                .stroke(color.opacity(0.15 * boost), lineWidth: 8 + level * 15)
                .blur(radius: 6 + level * 6)

            // Inner bright edge
            cornerShape
                .stroke(color.opacity(0.4 * boost), lineWidth: 2 + level * 4)
                .blur(radius: 1 + level * 2)
        }
        // Mask out the top edge — glow only on left, right, bottom
        .mask(
            LinearGradient(
                colors: [.clear, .white, .white],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.12)
            )
        )
        .scaleEffect(isPulsing ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.08), value: coachingState.audioLevel)
        .animation(.easeInOut(duration: 0.5), value: coachingState.flashSeverity == nil)
        .animation(.easeInOut(duration: 0.3), value: isPulsing)
        .onChange(of: coachingState.recentEvents.count) { _, _ in
            guard let last = coachingState.recentEvents.last else { return }

            // Flash on any warning or alert event
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
    }

    /// Active color: flash color overrides health-based color
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

    /// Base color from confidence score: red → orange → yellow → green
    private var healthColor: Color {
        let h = coachingState.healthFraction
        if h < 0.5 {
            return Color(hue: Double(h) * 0.32, saturation: 0.9, brightness: 0.9)
        } else {
            return Color(hue: 0.16 + Double(h - 0.5) * 0.34, saturation: 0.9, brightness: 0.9)
        }
    }
}

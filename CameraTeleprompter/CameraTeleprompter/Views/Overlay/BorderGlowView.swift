import SwiftUI

struct BorderGlowView: View {
    @Environment(CoachingState.self) private var coachingState
    @State private var isPulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(glowColor, lineWidth: 3)
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isPulsing)
            .animation(.easeInOut(duration: 0.5), value: coachingState.healthFraction)
            .onChange(of: coachingState.recentEvents.count) { _, _ in
                // Pulse on run-on detection
                if let last = coachingState.recentEvents.last,
                   case .runOn = last.type {
                    isPulsing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isPulsing = false
                    }
                }
            }
    }

    private var glowColor: Color {
        let h = coachingState.healthFraction
        // Interpolate red → yellow → green
        if h < 0.5 {
            // Red to yellow (hue 0 to 0.16)
            return Color(hue: Double(h) * 0.32, saturation: 0.9, brightness: 0.9)
        } else {
            // Yellow to green (hue 0.16 to 0.33)
            return Color(hue: 0.16 + Double(h - 0.5) * 0.34, saturation: 0.9, brightness: 0.9)
        }
    }
}

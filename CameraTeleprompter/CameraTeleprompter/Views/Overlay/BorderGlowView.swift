import SwiftUI

struct BorderGlowView: View {
    @Environment(CoachingState.self) private var coachingState
    @State private var isPulsing = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)

        ZStack {
            // Outer soft glow
            shape
                .stroke(glowColor.opacity(0.08), lineWidth: 20)
                .blur(radius: 12)

            // Mid glow
            shape
                .stroke(glowColor.opacity(0.15), lineWidth: 8)
                .blur(radius: 6)

            // Inner bright edge
            shape
                .stroke(glowColor.opacity(0.4), lineWidth: 2)
                .blur(radius: 1)
        }
        .scaleEffect(isPulsing ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.8), value: coachingState.healthFraction)
        .animation(.easeInOut(duration: 0.3), value: isPulsing)
        .onChange(of: coachingState.recentEvents.count) { _, _ in
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
        if h < 0.5 {
            return Color(hue: Double(h) * 0.32, saturation: 0.9, brightness: 0.9)
        } else {
            return Color(hue: 0.16 + Double(h - 0.5) * 0.34, saturation: 0.9, brightness: 0.9)
        }
    }
}

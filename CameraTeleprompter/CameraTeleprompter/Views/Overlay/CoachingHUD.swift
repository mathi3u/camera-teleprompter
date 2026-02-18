import SwiftUI

struct CoachingHUD: View {
    @Environment(CoachingState.self) private var coachingState

    var body: some View {
        HStack(spacing: 16) {
            // Confidence score
            HStack(spacing: 4) {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 8, height: 8)
                Text("\(coachingState.confidenceScore)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            // WPM gauge
            HStack(spacing: 4) {
                Image(systemName: "metronome")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(coachingState.wpm) wpm")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Pitch indicator
            if coachingState.currentPitch > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(Int(coachingState.currentPitch)) Hz")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            // Filler count badge
            if coachingState.fillerCount > 0 {
                HStack(spacing: 4) {
                    Text("\(coachingState.fillerCount)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.7))
                        .clipShape(Capsule())
                    Text("fillers")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }

    private var scoreColor: Color {
        let score = coachingState.confidenceScore
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        return .red
    }
}

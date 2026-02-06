import SwiftUI

struct VoiceLevelIndicator: View {
    @Environment(TeleprompterState.self) private var state

    /// Normalize dB level to 0...1 range
    private var normalizedLevel: CGFloat {
        // Map from -60dB...0dB to 0...1
        let clamped = max(-60, min(0, CGFloat(state.currentAudioLevel)))
        return (clamped + 60) / 60
    }

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(state.isSpeaking ? Color.green : Color.white.opacity(0.3))
                .frame(width: geo.size.width * normalizedLevel)
                .animation(.linear(duration: 0.05), value: normalizedLevel)
        }
    }
}

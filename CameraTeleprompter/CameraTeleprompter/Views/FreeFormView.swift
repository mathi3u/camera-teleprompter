import SwiftUI

/// No-script mode: shows live transcript text + CoachingHUD at bottom
struct FreeFormView: View {
    @Environment(TeleprompterState.self) private var state
    @Environment(CoachingState.self) private var coachingState

    var body: some View {
        VStack(spacing: 0) {
            // Live transcript area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(state.liveTranscript.isEmpty ? "Listening..." : state.liveTranscript)
                        .font(.system(size: state.fontSize, weight: .regular, design: .default))
                        .foregroundStyle(state.liveTranscript.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .id("transcript")
                }
                .onChange(of: state.liveTranscript) { _, _ in
                    withAnimation {
                        proxy.scrollTo("transcript", anchor: .bottom)
                    }
                }
            }

            // Coaching HUD at bottom
            CoachingHUD()
                .padding(.bottom, 4)
        }
    }
}

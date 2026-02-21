import SwiftUI

struct OverlayContentView: View {
    @Environment(TeleprompterState.self) private var state
    @Environment(CoachingState.self) private var coachingState

    var body: some View {
        ZStack {
            Color.clear

            switch state.phase {
            case .idle:
                EmptyView()
            case .countdown(let count):
                CountdownView(count: count)
            case .running:
                VStack(spacing: 0) {
                    if state.speechMode == .freeForm && state.isCoachingEnabled {
                        FreeFormView()
                    } else {
                        TeleprompterScrollView()
                    }
                    if state.isVoiceControlEnabled {
                        VoiceLevelIndicator()
                            .frame(height: 4)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                    }
                }
            }

            // Coaching overlays (layered on top when running + coaching enabled)
            if state.isCoachingEnabled, case .running = state.phase {
                FloatingMessageOverlay()
                    .allowsHitTesting(false)
            }
        }
    }
}

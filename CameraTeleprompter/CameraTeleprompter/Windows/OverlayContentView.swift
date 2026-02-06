import SwiftUI

struct OverlayContentView: View {
    @Environment(TeleprompterState.self) private var state

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
                    TeleprompterScrollView()
                    if state.isVoiceControlEnabled {
                        VoiceLevelIndicator()
                            .frame(height: 4)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
    }
}

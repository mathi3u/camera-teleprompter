import SwiftUI

struct MainWindowView: View {
    @Environment(TeleprompterState.self) private var state

    var onStart: () -> Void
    var onStop: () -> Void

    var body: some View {
        @Bindable var state = state

        ZStack {
            Color.black.opacity(0.70).ignoresSafeArea()

            switch state.phase {
            case .idle:
                TextEditor(text: $state.currentScript.body)
                    .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            onStart()
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(state.currentScript.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.trailing, 12)
                        .padding(.bottom, 8)
                    }
            case .countdown(let count):
                CountdownView(count: count)
            case .running:
                TeleprompterScrollView()
                    .environment(state)
            }
        }
    }
}

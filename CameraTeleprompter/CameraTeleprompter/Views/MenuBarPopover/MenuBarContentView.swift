import SwiftUI

struct MenuBarContentView: View {
    @Environment(TeleprompterState.self) private var state

    var onStart: () -> Void
    var onStop: () -> Void

    @State private var selectedTab: Tab = .script

    enum Tab: String, CaseIterable {
        case script = "Script"
        case settings = "Settings"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Content
            switch selectedTab {
            case .script:
                ScriptEditorView()
            case .settings:
                SettingsView()
            }

            Divider()

            // Controls
            HStack {
                if state.isRunning || state.isOverlayVisible {
                    Button("Stop") {
                        onStop()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                } else {
                    Button("Start") {
                        onStart()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(state.currentScript.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}

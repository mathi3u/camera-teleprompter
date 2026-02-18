import SwiftUI

/// Shows the last few words of the live transcript, fading older lines
struct LiveTranscriptView: View {
    let transcript: String

    var body: some View {
        let lines = recentLines
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(opacity(for: index, of: lines.count)))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 38, alignment: .bottom)
        .clipped()
        .animation(.easeOut(duration: 0.15), value: transcript)
    }

    /// Split transcript into last 2 lines of ~8 words each
    private var recentLines: [String] {
        let words = transcript.split(separator: " ")
        guard !words.isEmpty else { return [] }
        let chunkSize = 8
        let startIndex = max(0, words.count - chunkSize * 2)
        let recent = Array(words[startIndex...])
        var lines: [String] = []
        for i in stride(from: 0, to: recent.count, by: chunkSize) {
            let end = min(i + chunkSize, recent.count)
            lines.append(recent[i..<end].joined(separator: " "))
        }
        // Keep last 2 lines max
        if lines.count > 2 {
            lines = Array(lines.suffix(2))
        }
        return lines
    }

    private func opacity(for index: Int, of total: Int) -> Double {
        guard total > 1 else { return 0.6 }
        // Older lines (lower index) are more faded
        return index == total - 1 ? 0.6 : 0.3
    }
}

/// Helper to bridge SwiftUI openSettings action to NSMenuItem targets
final class MenuActionHelper: NSObject {
    static let shared = MenuActionHelper()
    var openSettingsAction: (() -> Void)?

    @objc func openPreferences() {
        openSettingsAction?()
        // Ensure the settings window appears above the floating main window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows where window != NSApp.windows.first {
                if window.isVisible {
                    window.level = .floating
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
}

struct MainWindowView: View {
    @Environment(TeleprompterState.self) private var state
    @Environment(CoachingState.self) private var coachingState
    @Environment(\.openSettings) private var openSettings
    @State private var rightClickMonitor: Any?
    @State private var keyboardMonitor: Any?

    var onStart: () -> Void
    var onStop: () -> Void

    private var hasScript: Bool {
        !state.currentScript.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            // Main content area with rounded corners
            ZStack {
                Color.black.opacity(state.windowOpacity)

                switch state.phase {
                case .idle:
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $state.currentScript.body)
                            .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .padding(12)

                        if state.currentScript.body.isEmpty {
                            Text("Optional: script goes here")
                                .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(12)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                case .countdown(let count):
                    CountdownView(count: count)
                case .running:
                    if hasScript {
                        TeleprompterScrollView()
                            .environment(state)
                    } else {
                        FreeFormView()
                    }
                }

                // Coaching radiance (layered on top when running + coaching enabled)
                if state.isCoachingEnabled, case .running = state.phase {
                    BorderGlowView()
                        .allowsHitTesting(false)
                    FloatingMessageOverlay()
                        .allowsHitTesting(false)
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 0))

            // Live transcript — fading words below the window
            if state.isCoachingEnabled, case .running = state.phase {
                LiveTranscriptView(transcript: state.liveTranscript)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }

            // Floating toolbar — transparent area below window content
            HStack(spacing: 8) {
                Spacer()

                Button {
                    state.isEdgeLightEnabled.toggle()
                } label: {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(state.isEdgeLightEnabled ? .yellow : .white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(state.isEdgeLightEnabled ? 0.15 : 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Toggle Edge Light")

                Button {
                    if case .running = state.phase {
                        onStop()
                    } else if case .idle = state.phase {
                        onStart()
                    }
                } label: {
                    Image(systemName: state.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(state.isRunning ? "Stop" : "Start")
            }
            .padding(.top, 6)
            .padding(.trailing, 4)
            .padding(.bottom, 2)
        }
        .onAppear {
            MenuActionHelper.shared.openSettingsAction = { openSettings() }
            installRightClickMonitor()
            installKeyboardMonitor()
        }
        .onDisappear {
            removeRightClickMonitor()
            removeKeyboardMonitor()
        }
    }

    private func installRightClickMonitor() {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            let menu = NSMenu()
            let helper = MenuActionHelper.shared

            if case .idle = state.phase {
                menu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }

            let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(MenuActionHelper.openPreferences), keyEquivalent: ",")
            prefsItem.target = helper
            menu.addItem(prefsItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

            if let contentView = event.window?.contentView {
                NSMenu.popUpContextMenu(menu, with: event, for: contentView)
            }
            return nil
        }
    }

    private func installKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // Cmd+, opens Preferences
            if flags.contains(.command) && event.keyCode == 43 {
                MenuActionHelper.shared.openPreferences()
                return nil
            }
            // Cmd+Enter starts/stops
            if flags.contains(.command) && event.keyCode == 36 {
                if case .idle = state.phase {
                    onStart()
                    return nil
                }
            }
            return event
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }

    private func removeRightClickMonitor() {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
            rightClickMonitor = nil
        }
    }
}

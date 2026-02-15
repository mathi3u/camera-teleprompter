import SwiftUI

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
    @Environment(\.openSettings) private var openSettings
    @State private var rightClickMonitor: Any?
    @State private var keyboardMonitor: Any?

    var onStart: () -> Void
    var onStop: () -> Void

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            ZStack {
                Color.black.opacity(state.windowOpacity).ignoresSafeArea()

                switch state.phase {
                case .idle:
                    if state.isCoachingEnabled && state.speechMode == .freeForm {
                        // Free-form mode: no script editor, just a start prompt
                        VStack(spacing: 12) {
                            if state.isCoachingEnabled {
                                Picker("", selection: $state.speechMode) {
                                    Text("Script").tag(SpeechMode.teleprompter)
                                    Text("Free").tag(SpeechMode.freeForm)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }
                            Text("Press play to start")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.4))
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
                        }
                    } else {
                        VStack(spacing: 0) {
                            if state.isCoachingEnabled {
                                Picker("", selection: $state.speechMode) {
                                    Text("Script").tag(SpeechMode.teleprompter)
                                    Text("Free").tag(SpeechMode.freeForm)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                                .padding(.top, 8)
                            }
                            TextEditor(text: $state.currentScript.body)
                                .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                        }
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
                    }
                case .countdown(let count):
                    CountdownView(count: count)
                case .running:
                    TeleprompterScrollView()
                        .environment(state)
                }
            }

            Text("\u{2318}\u{23CE}: play  |  Space: pause  |  \u{2190}\u{2192}: speed  |  \u{2191}\u{2193}: skip  |  +/-: font  |  Esc: stop")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.black.opacity(state.windowOpacity))
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
            // Cmd+Enter starts playback
            if flags.contains(.command) && event.keyCode == 36 {
                if case .idle = state.phase {
                    // In freeForm mode, no script needed
                    if state.speechMode == .freeForm && state.isCoachingEnabled {
                        onStart()
                        return nil
                    }
                    // In teleprompter mode, require script
                    if !state.currentScript.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onStart()
                        return nil
                    }
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

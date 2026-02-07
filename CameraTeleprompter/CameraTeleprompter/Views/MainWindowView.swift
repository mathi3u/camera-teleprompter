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

    var onStart: () -> Void
    var onStop: () -> Void

    var body: some View {
        @Bindable var state = state

        ZStack {
            Color.black.opacity(state.windowOpacity).ignoresSafeArea()

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
        .onAppear {
            MenuActionHelper.shared.openSettingsAction = { openSettings() }
            installRightClickMonitor()
        }
        .onDisappear { removeRightClickMonitor() }
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

    private func removeRightClickMonitor() {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
            rightClickMonitor = nil
        }
    }
}

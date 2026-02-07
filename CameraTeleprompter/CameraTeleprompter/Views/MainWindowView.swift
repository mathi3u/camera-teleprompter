import SwiftUI

struct MainWindowView: View {
    @Environment(TeleprompterState.self) private var state
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
        .onAppear { installRightClickMonitor() }
        .onDisappear { removeRightClickMonitor() }
    }

    private func installRightClickMonitor() {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            let menu = NSMenu()

            if case .idle = state.phase {
                menu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
            }

            menu.addItem(NSMenuItem(title: "Preferences...", action: Selector(("showSettingsWindow:")), keyEquivalent: ","))
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

import SwiftUI

@main
struct CameraTeleprompterApp: App {
    @State private var state = TeleprompterState()
    @State private var keyMonitor: Any?
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView(
                onStart: startTeleprompter,
                onStop: stopTeleprompter
            )
            .environment(state)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 220)
        .defaultPosition(.top)

        Settings {
            PreferencesView()
                .environment(state)
        }
    }

    private func startTeleprompter() {
        state.scrollEngine.speed = state.scrollSpeed
        state.phase = .running
        state.scrollEngine.start()
        installKeyMonitor()
    }

    private func stopTeleprompter() {
        state.scrollEngine.stop()
        state.phase = .idle
        removeKeyMonitor()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space - pause/resume
                state.scrollEngine.togglePause()
                return nil
            case 123: // Left arrow - slower
                state.scrollEngine.adjustSpeed(by: -5)
                return nil
            case 124: // Right arrow - faster
                state.scrollEngine.adjustSpeed(by: 5)
                return nil
            case 125: // Down arrow - skip forward
                state.scrollNudge += 1
                return nil
            case 126: // Up arrow - skip back
                state.scrollNudge -= 1
                return nil
            case 53: // Escape - stop
                stopTeleprompter()
                return nil
            case 24: // + key (=+)
                state.fontSize = min(72, state.fontSize + 2)
                return nil
            case 27: // - key
                state.fontSize = max(10, state.fontSize - 2)
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

// MARK: - App Delegate for window positioning

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApplication.shared.windows.first else { return }
            guard let screen = window.screen ?? NSScreen.main else { return }

            let screenFrame = screen.frame
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
            let windowWidth: CGFloat = 500
            let windowHeight: CGFloat = 220
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.maxY - menuBarHeight - windowHeight

            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden

            // Hide traffic light buttons
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Make sure window can receive key events
            window.makeKey()
        }
    }
}

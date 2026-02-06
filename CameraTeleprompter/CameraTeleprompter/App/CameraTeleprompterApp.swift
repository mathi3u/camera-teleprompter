import SwiftUI

@main
struct CameraTeleprompterApp: App {
    @State private var state = TeleprompterState()
    @State private var overlayController: OverlayWindowController?
    @State private var audioMonitor = AudioLevelMonitor()
    @State private var countdownTimer: Timer?
    @State private var keyMonitor: Any?

    var body: some Scene {
        MenuBarExtra("Teleprompter", systemImage: "text.viewfinder") {
            MenuBarContentView(
                onStart: startTeleprompter,
                onStop: stopTeleprompter
            )
            .environment(state)
        }
        .menuBarExtraStyle(.window)
    }

    private func startTeleprompter() {
        // Save script
        saveCurrentScript()

        // Sync settings to engine
        state.scrollEngine.speed = state.scrollSpeed

        // Create overlay
        if overlayController == nil {
            overlayController = OverlayWindowController(state: state)
        }
        overlayController?.show(mode: state.displayMode)

        // Start countdown
        state.phase = .countdown(3)
        var count = 3
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            count -= 1
            if count > 0 {
                state.phase = .countdown(count)
            } else {
                timer.invalidate()
                countdownTimer = nil
                beginScrolling()
            }
        }
    }

    private func beginScrolling() {
        state.phase = .running
        state.scrollEngine.start()

        // Start voice monitoring if enabled
        if state.isVoiceControlEnabled {
            audioMonitor.threshold = state.voiceThreshold
            audioMonitor.start()
        }

        // Install keyboard monitor
        installKeyMonitor()

        // Start voice-scroll sync
        startVoiceSync()
    }

    private func stopTeleprompter() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        state.scrollEngine.stop()
        audioMonitor.stop()
        overlayController?.close()
        state.phase = .idle
        state.isSpeaking = false
        state.currentAudioLevel = -160
        removeKeyMonitor()
    }

    private func saveCurrentScript() {
        var scripts = ScriptStore.load()
        if let idx = scripts.firstIndex(where: { $0.id == state.currentScript.id }) {
            scripts[idx] = state.currentScript
        } else {
            scripts.append(state.currentScript)
        }
        ScriptStore.save(scripts)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space
                state.scrollEngine.togglePause()
                return nil
            case 126: // Up arrow
                state.scrollEngine.adjustSpeed(by: 10)
                return nil
            case 125: // Down arrow
                state.scrollEngine.adjustSpeed(by: -10)
                return nil
            case 53: // Escape
                stopTeleprompter()
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

    private func startVoiceSync() {
        // Poll audio levels and sync to scroll engine
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard state.isRunning else {
                timer.invalidate()
                return
            }

            state.currentAudioLevel = audioMonitor.currentLevel
            state.isSpeaking = audioMonitor.isSpeaking

            if state.isVoiceControlEnabled {
                if audioMonitor.isSpeaking {
                    state.scrollEngine.resume()
                } else {
                    state.scrollEngine.pause()
                }
            }
        }
    }
}

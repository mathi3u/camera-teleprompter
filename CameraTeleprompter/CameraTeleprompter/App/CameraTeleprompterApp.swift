import SwiftUI

@main
struct CameraTeleprompterApp: App {
    @State private var state = TeleprompterState()
    @State private var coachingState = CoachingState()
    @State private var keyMonitor: Any?
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Coaching services
    @State private var speechAnalyzer = SpeechAnalyzer()
    @State private var speechTranscriber = SpeechTranscriber()
    @State private var pitchTracker = RealTimePitchTracker()
    @State private var audioPipeline = AudioPipelineController()
    @State private var edgeLightController = EdgeLightController()
    @State private var coachingStartTime: Date?
    @State private var lastPitchWarning: Date = .distantPast

    var body: some Scene {
        WindowGroup {
            MainWindowView(
                onStart: startTeleprompter,
                onStop: stopTeleprompter
            )
            .environment(state)
            .environment(coachingState)
            .onChange(of: state.edgeLightMode) { _, mode in
                if mode == .off {
                    edgeLightController.close()
                } else {
                    edgeLightController.show(brightness: mode.brightness)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 620, height: 320)

        Settings {
            PreferencesView()
                .environment(state)
                .environment(coachingState)
        }
    }

    private func startTeleprompter() {
        // Auto-detect mode: script has text → teleprompter, empty → freeForm
        let hasScript = !state.currentScript.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        state.speechMode = hasScript ? .teleprompter : .freeForm

        state.scrollEngine.speed = state.scrollSpeed
        state.phase = .running
        if hasScript {
            state.scrollEngine.start()
        }
        installKeyMonitor()

        if state.isCoachingEnabled {
            ensureSpeechAuthThenStartCoaching()
        }

    }

    private func stopTeleprompter() {
        state.scrollEngine.stop()
        state.phase = .idle
        removeKeyMonitor()
        stopCoaching()
    }

    private func ensureSpeechAuthThenStartCoaching() {
        let status = SpeechTranscriber.authorizationStatus
        switch status {
        case .authorized:
            startCoaching()
        case .notDetermined:
            SpeechTranscriber.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.startCoaching()
                    } else {
                        self.showSpeechAuthAlert()
                    }
                }
            }
        default:
            showSpeechAuthAlert()
        }
    }

    private func showSpeechAuthAlert() {
        let alert = NSAlert()
        alert.messageText = "Speech Recognition Required"
        alert.informativeText = "Enable Speech Recognition for Toner in System Settings → Privacy & Security → Speech Recognition."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Skip")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")!)
        }
    }

    private func startCoaching() {
        coachingState.reset()
        coachingStartTime = Date()
        state.liveTranscript = ""

        // Set up transcriber callbacks
        speechTranscriber.onPartialTranscript = { [self] transcript in
            state.liveTranscript = transcript
            coachingState.debugStatus = "words=\(transcript.split(separator: " ").count)"
            let events = speechAnalyzer.processPartialTranscript(transcript)
            for event in events {
                coachingState.addEvent(event)
                if case .fillerWord = event.type {
                    coachingState.fillerCount += 1
                }
                if case .hedging = event.type {
                    coachingState.hedgingCount += 1
                }

                // Flash glow color on warnings/alerts
                if event.severity == .warning || event.severity == .alert {
                    coachingState.flashSeverity = event.severity
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        coachingState.flashSeverity = nil
                    }
                }
            }

            // Detect sentence ends for uptalk tracking
            if transcript.contains(where: { $0 == "." || $0 == "!" || $0 == "?" }) {
                pitchTracker.markSentenceEnd()
                if pitchTracker.sentenceCount > 0 {
                    let uptalkRatio = Double(pitchTracker.uptalkCount) / Double(pitchTracker.sentenceCount)
                    coachingState.applyUptalkRatio(uptalkRatio)
                }
            }

            // Update rates based on elapsed time
            if let start = coachingStartTime {
                let minutes = Date().timeIntervalSince(start) / 60
                if minutes > 0.1 {
                    let wordCount = transcript.split(separator: " ").count
                    let wpm = Int(Double(wordCount) / minutes)
                    let prevWpm = coachingState.wpm
                    coachingState.applyPace(wpm: wpm)
                    coachingState.applyFillerRate(Double(coachingState.fillerCount) / minutes)
                    coachingState.applyHedgingRate(Double(coachingState.hedgingCount) / minutes)

                    // Alert on pace changes (with threshold to avoid spam)
                    if wpm > 180 && prevWpm <= 180 {
                        let event = CoachingEvent(type: .paceTooFast, message: "Slow down", severity: .warning)
                        coachingState.addEvent(event)
                        coachingState.flashSeverity = .warning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            coachingState.flashSeverity = nil
                        }
                    } else if wpm < 100 && prevWpm >= 100 {
                        let event = CoachingEvent(type: .paceTooSlow, message: "Pick up pace", severity: .info)
                        coachingState.addEvent(event)
                    }
                }
            }
        }

        // Configure audio pipeline
        let levelMonitor = AudioLevelMonitor()
        levelMonitor.threshold = state.voiceThreshold
        audioPipeline.configure(
            levelMonitor: levelMonitor,
            transcriber: speechTranscriber,
            pitchTracker: pitchTracker,
            onPitch: { [self] pitch in
                coachingState.currentPitch = pitch
                // Flag high pitch with 5s cooldown
                if pitchTracker.isPitchHigh,
                   Date().timeIntervalSince(lastPitchWarning) > 5 {
                    lastPitchWarning = Date()
                    let event = CoachingEvent(
                        type: .pitchTooHigh,
                        message: "Pitch high",
                        severity: .warning
                    )
                    coachingState.addEvent(event)
                    coachingState.flashSeverity = .warning
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        coachingState.flashSeverity = nil
                    }
                }
            },
            onLevel: { [self] db in
                coachingState.updateAudioLevel(db: db)
            }
        )

        speechTranscriber.onError = { [self] error in
            coachingState.debugStatus = "ERR: \(error.localizedDescription)"
        }

        speechTranscriber.start()
        audioPipeline.start()

        let auth = SpeechTranscriber.authorizationStatus.rawValue
        coachingState.debugStatus = "auth=\(auth) tx=\(speechTranscriber.isTranscribing) eng=\(audioPipeline.isRunning)"
    }

    private func stopCoaching() {
        audioPipeline.stop()
        speechTranscriber.stop()
        speechAnalyzer.reset()
        pitchTracker.reset()
        coachingStartTime = nil
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
            let glowPad: CGFloat = 60
            let windowWidth: CGFloat = 500 + glowPad * 2
            let windowHeight: CGFloat = 260 + glowPad
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.maxY - windowHeight

            // Auto-hide menu bar so window can touch the very top
            NSApp.presentationOptions = [.autoHideMenuBar]

            window.styleMask = [.borderless]
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
            window.level = .statusBar
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false

            // Make sure window can receive key events
            window.makeKey()
        }
    }
}

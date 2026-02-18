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
    @State private var speechAuthRequested = false

    var body: some Scene {
        WindowGroup {
            MainWindowView(
                onStart: startTeleprompter,
                onStop: stopTeleprompter
            )
            .environment(state)
            .environment(coachingState)
            .onChange(of: state.isEdgeLightEnabled) { _, enabled in
                if enabled {
                    edgeLightController.show()
                } else {
                    edgeLightController.close()
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 220)
        .defaultPosition(.top)

        Settings {
            PreferencesView()
                .environment(state)
                .environment(coachingState)
        }
    }

    private func startTeleprompter() {
        state.scrollEngine.speed = state.scrollSpeed
        state.phase = .running
        if state.speechMode == .teleprompter {
            state.scrollEngine.start()
        }
        installKeyMonitor()

        if state.isCoachingEnabled {
            startCoaching()
        }

    }

    private func stopTeleprompter() {
        state.scrollEngine.stop()
        state.phase = .idle
        removeKeyMonitor()
        stopCoaching()
    }

    private func startCoaching() {
        coachingState.reset()
        coachingStartTime = Date()
        state.liveTranscript = ""

        // Request speech authorization if needed
        if !speechAuthRequested {
            speechAuthRequested = true
            SpeechTranscriber.requestAuthorization { _ in }
        }

        // Set up transcriber callbacks
        speechTranscriber.onPartialTranscript = { [self] transcript in
            state.liveTranscript = transcript
            let events = speechAnalyzer.processPartialTranscript(transcript)
            for event in events {
                coachingState.addEvent(event)
                if case .fillerWord = event.type {
                    coachingState.fillerCount += 1
                }
                if case .hedging = event.type {
                    coachingState.hedgingCount += 1
                }
            }

            // Update rates based on elapsed time
            if let start = coachingStartTime {
                let minutes = Date().timeIntervalSince(start) / 60
                if minutes > 0.1 {
                    let wordCount = transcript.split(separator: " ").count
                    let wpm = Int(Double(wordCount) / minutes)
                    coachingState.applyPace(wpm: wpm)
                    coachingState.applyFillerRate(Double(coachingState.fillerCount) / minutes)
                    coachingState.applyHedgingRate(Double(coachingState.hedgingCount) / minutes)
                }
            }
        }

        // Configure audio pipeline
        let levelMonitor = AudioLevelMonitor()
        levelMonitor.threshold = state.voiceThreshold
        audioPipeline.configure(
            levelMonitor: levelMonitor,
            transcriber: speechTranscriber,
            pitchTracker: pitchTracker
        )

        speechTranscriber.start()
        audioPipeline.start()
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

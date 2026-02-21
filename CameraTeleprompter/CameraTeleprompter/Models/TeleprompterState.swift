import SwiftUI

enum DisplayMode: String, CaseIterable, Codable {
    case notch = "Notch"
    case floating = "Floating"
}

enum EdgeLightMode: String, CaseIterable {
    case off, medium, high

    var next: EdgeLightMode {
        switch self {
        case .off: return .medium
        case .medium: return .high
        case .high: return .off
        }
    }

    var brightness: CGFloat {
        switch self {
        case .off: return 0
        case .medium: return 1.0
        case .high: return 2.0
        }
    }
}

enum AppPhase {
    case idle
    case countdown(Int)
    case running
}

@Observable
final class TeleprompterState {
    // MARK: - Script
    var currentScript: Script = Script()
    var scripts: [Script] = []

    // MARK: - Appearance
    var fontSize: CGFloat = 24
    var textColor: Color = .white
    var scrollSpeed: CGFloat = 30
    var windowOpacity: CGFloat = 0.70
    var displayMode: DisplayMode = .notch

    // MARK: - Audio
    var voiceThreshold: Float = -30 // dB
    var currentAudioLevel: Float = -160
    var isSpeaking: Bool = false
    var isVoiceControlEnabled: Bool = false

    // MARK: - Coaching
    var speechMode: SpeechMode = .teleprompter
    var isCoachingEnabled: Bool = true
    var liveTranscript: String = ""

    // MARK: - Edge Light
    var edgeLightMode: EdgeLightMode = .off

    // MARK: - State
    var phase: AppPhase = .idle
    var isOverlayVisible: Bool = false
    /// Accumulated skip nudge from arrow keys (consumed by scroll view)
    var scrollNudge: CGFloat = 0

    // MARK: - Engines
    let scrollEngine = ScrollEngine()

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }
}

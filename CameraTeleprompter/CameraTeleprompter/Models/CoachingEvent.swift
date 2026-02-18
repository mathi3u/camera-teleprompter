import Foundation

enum CoachingEventSeverity {
    case info
    case warning
    case alert
    case positive
}

enum CoachingEventType {
    case fillerWord(String)
    case hedging(String)
    case runOn
    case paceTooFast
    case paceTooSlow
    case uptalk
    case pitchTooHigh
    case goodStreak
}

struct CoachingEvent: Identifiable {
    let id = UUID()
    let type: CoachingEventType
    let message: String
    let severity: CoachingEventSeverity
    let timestamp: Date

    init(type: CoachingEventType, message: String, severity: CoachingEventSeverity, timestamp: Date = Date()) {
        self.type = type
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
    }
}

import Foundation

@Observable
final class CoachingState {
    var confidenceScore: Int = 100
    var fillerCount: Int = 0
    var hedgingCount: Int = 0
    var wpm: Int = 0
    var recentEvents: [CoachingEvent] = []
    var totalWordCount: Int = 0
    var startTime: Date?

    /// Normalized audio level 0...1 for visual reactivity
    var audioLevel: CGFloat = 0

    /// Current pitch in Hz (0 = no pitch detected)
    var currentPitch: Float = 0

    /// Flash severity for reactive glow color changes (set on events, auto-clears)
    var flashSeverity: CoachingEventSeverity? = nil

    // Deduction tracking
    private(set) var fillerDeduction: Int = 0
    private(set) var hedgingDeduction: Int = 0
    private(set) var runOnDeduction: Int = 0
    private(set) var paceDeduction: Int = 0
    private(set) var uptalkDeduction: Int = 0

    var healthFraction: CGFloat {
        CGFloat(max(0, min(100, confidenceScore))) / 100.0
    }

    private static let maxEvents = 20

    func addEvent(_ event: CoachingEvent) {
        recentEvents.append(event)
        if recentEvents.count > Self.maxEvents {
            recentEvents.removeFirst(recentEvents.count - Self.maxEvents)
        }
    }

    /// Apply filler rate deduction: >5/min → up to -25
    func applyFillerRate(_ rate: Double) {
        if rate > 5 {
            fillerDeduction = min(25, Int(round((rate - 5) * 3)))
        } else {
            fillerDeduction = 0
        }
        recalculateScore()
    }

    /// Apply hedging rate deduction: >3/min → up to -20
    func applyHedgingRate(_ rate: Double) {
        if rate > 3 {
            hedgingDeduction = min(20, Int(round((rate - 3) * 4)))
        } else {
            hedgingDeduction = 0
        }
        recalculateScore()
    }

    /// Apply run-on ratio deduction: >0.2 → up to -15
    func applyRunOnRatio(_ ratio: Double) {
        if ratio > 0.2 {
            runOnDeduction = min(15, Int(round(ratio * 30)))
        } else {
            runOnDeduction = 0
        }
        recalculateScore()
    }

    /// Apply pace deduction: outside 100-180 wpm → -10
    func applyPace(wpm: Int) {
        self.wpm = wpm
        if wpm < 100 || wpm > 180 {
            paceDeduction = 10
        } else {
            paceDeduction = 0
        }
        recalculateScore()
    }

    /// Apply uptalk deduction: >30% of sentences → up to -15
    func applyUptalkRatio(_ ratio: Double) {
        if ratio > 0.3 {
            uptalkDeduction = min(15, Int(round(ratio * 30)))
        } else {
            uptalkDeduction = 0
        }
        recalculateScore()
    }

    private func recalculateScore() {
        let total = fillerDeduction + hedgingDeduction + runOnDeduction + paceDeduction + uptalkDeduction
        confidenceScore = max(0, 100 - total)
    }

    func reset() {
        confidenceScore = 100
        fillerCount = 0
        hedgingCount = 0
        wpm = 0
        recentEvents = []
        totalWordCount = 0
        startTime = nil
        fillerDeduction = 0
        hedgingDeduction = 0
        runOnDeduction = 0
        paceDeduction = 0
        uptalkDeduction = 0
        audioLevel = 0
        currentPitch = 0
        flashSeverity = nil
    }

    /// Update audio level from dB value (-60…0 range)
    func updateAudioLevel(db: Float) {
        audioLevel = CGFloat(max(0, min(1, (db + 50) / 40)))
    }
}

import Foundation

final class SpeechAnalyzer {

    // Filler words from voice-tone-helper analysis.ts
    static let fillerWords: [String] = [
        "um", "uh", "uhh", "umm", "erm", "er",
        "like", "you know", "i mean", "right",
        "basically", "actually", "literally", "honestly",
        "so", "well", "anyway", "anyways",
        "kind of", "kinda", "sort of", "sorta",
        "i guess", "i think", "i suppose",
        "just", "really", "very", "totally",
        "definitely", "absolutely", "obviously"
    ]

    // Hedging phrases from voice-tone-helper analysis.ts
    static let hedgingPhrases: [String] = [
        "i think", "i believe", "i feel like",
        "maybe", "perhaps", "probably", "possibly",
        "kind of", "sort of", "somewhat",
        "i guess", "i suppose",
        "not sure", "not certain",
        "might be", "could be", "may be",
        "in my opinion", "it seems like",
        "i don't know"
    ]

    // Single-word fillers for fast lookup
    private static let singleWordFillers: Set<String> = {
        Set(fillerWords.filter { !$0.contains(" ") })
    }()

    // Multi-word fillers
    private static let multiWordFillers: [String] = {
        fillerWords.filter { $0.contains(" ") }
    }()

    // Single-word hedges
    private static let singleWordHedges: Set<String> = {
        Set(hedgingPhrases.filter { !$0.contains(" ") })
    }()

    // Multi-word hedges
    private static let multiWordHedges: [String] = {
        hedgingPhrases.filter { $0.contains(" ") }
    }()

    private var previousTranscript: String = ""
    private var wordCountSinceLastSentence: Int = 0

    /// Extract newly spoken text by diffing previous and current transcripts
    func extractNewText(previous: String, current: String) -> String {
        guard !previous.isEmpty else { return current }
        guard current != previous else { return "" }

        let prevWords = previous.split(separator: " ")
        let currWords = current.split(separator: " ")

        // Find where new words start
        let commonCount = min(prevWords.count, currWords.count)
        var matchCount = 0
        for i in 0..<commonCount {
            if prevWords[i] == currWords[i] {
                matchCount += 1
            } else {
                break
            }
        }

        if matchCount >= prevWords.count {
            // All previous words match - new words are the suffix
            let newWords = currWords[matchCount...]
            return newWords.joined(separator: " ")
        }

        return ""
    }

    /// Analyze a chunk of text and return coaching events
    func analyzeText(_ text: String) -> [CoachingEvent] {
        let lower = text.lowercased()
        var events: [CoachingEvent] = []

        // Detect single-word fillers
        let words = lower.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        for word in words {
            let cleaned = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if Self.singleWordFillers.contains(cleaned) {
                events.append(CoachingEvent(
                    type: .fillerWord(cleaned),
                    message: "\"\(cleaned)\"",
                    severity: .warning
                ))
            }
        }

        // Detect multi-word fillers
        for phrase in Self.multiWordFillers {
            var searchRange = lower.startIndex..<lower.endIndex
            while let range = lower.range(of: phrase, options: .caseInsensitive, range: searchRange) {
                // Check word boundaries
                let beforeOK = range.lowerBound == lower.startIndex ||
                    lower[lower.index(before: range.lowerBound)].isWhitespace
                let afterOK = range.upperBound == lower.endIndex ||
                    lower[range.upperBound].isWhitespace ||
                    lower[range.upperBound].isPunctuation
                if beforeOK && afterOK {
                    events.append(CoachingEvent(
                        type: .fillerWord(phrase),
                        message: "\"\(phrase)\"",
                        severity: .warning
                    ))
                }
                searchRange = range.upperBound..<lower.endIndex
            }
        }

        // Detect single-word hedges
        for word in words {
            let cleaned = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if Self.singleWordHedges.contains(cleaned) {
                events.append(CoachingEvent(
                    type: .hedging(cleaned),
                    message: "\"\(cleaned)\"",
                    severity: .warning
                ))
            }
        }

        // Detect multi-word hedges
        for phrase in Self.multiWordHedges {
            var searchRange = lower.startIndex..<lower.endIndex
            while let range = lower.range(of: phrase, options: .caseInsensitive, range: searchRange) {
                let beforeOK = range.lowerBound == lower.startIndex ||
                    lower[lower.index(before: range.lowerBound)].isWhitespace
                let afterOK = range.upperBound == lower.endIndex ||
                    lower[range.upperBound].isWhitespace ||
                    lower[range.upperBound].isPunctuation
                if beforeOK && afterOK {
                    events.append(CoachingEvent(
                        type: .hedging(phrase),
                        message: "\"\(phrase)\"",
                        severity: .warning
                    ))
                }
                searchRange = range.upperBound..<lower.endIndex
            }
        }

        // Detect run-on sentences (>35 words without sentence-ending punctuation)
        wordCountSinceLastSentence += words.count
        let hasSentenceEnd = text.contains(where: { $0 == "." || $0 == "!" || $0 == "?" })
        if hasSentenceEnd {
            wordCountSinceLastSentence = 0
        } else if wordCountSinceLastSentence > 35 {
            events.append(CoachingEvent(
                type: .runOn,
                message: "Long sentence",
                severity: .alert
            ))
        }

        return events
    }

    /// Process a new partial transcript from speech recognition
    func processPartialTranscript(_ current: String) -> [CoachingEvent] {
        let newText = extractNewText(previous: previousTranscript, current: current)
        previousTranscript = current
        guard !newText.isEmpty else { return [] }
        return analyzeText(newText)
    }

    func reset() {
        previousTranscript = ""
        wordCountSinceLastSentence = 0
    }
}

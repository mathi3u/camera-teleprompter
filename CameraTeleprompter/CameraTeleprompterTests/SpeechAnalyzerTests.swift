import XCTest
@testable import CameraTeleprompter

final class SpeechAnalyzerTests: XCTestCase {

    var analyzer: SpeechAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = SpeechAnalyzer()
    }

    // MARK: - extractNewText diffing

    func testExtractNewTextEmptyPrevious() {
        let result = analyzer.extractNewText(previous: "", current: "hello world")
        XCTAssertEqual(result, "hello world")
    }

    func testExtractNewTextNoChange() {
        let result = analyzer.extractNewText(previous: "hello world", current: "hello world")
        XCTAssertEqual(result, "")
    }

    func testExtractNewTextAppendedWords() {
        let result = analyzer.extractNewText(previous: "hello world", current: "hello world how are you")
        XCTAssertEqual(result, "how are you")
    }

    func testExtractNewTextSingleWordAppended() {
        let result = analyzer.extractNewText(previous: "the quick brown", current: "the quick brown fox")
        XCTAssertEqual(result, "fox")
    }

    // MARK: - Filler detection

    func testDetectsUm() {
        let events = analyzer.analyzeText("um I was thinking about um that thing")
        let fillers = events.filter { if case .fillerWord = $0.type { return true }; return false }
        XCTAssertEqual(fillers.count, 2)
    }

    func testDetectsUh() {
        let events = analyzer.analyzeText("uh what was I saying")
        let fillers = events.filter { if case .fillerWord = $0.type { return true }; return false }
        XCTAssertEqual(fillers.count, 1)
    }

    func testDetectsLike() {
        let events = analyzer.analyzeText("it was like totally like amazing")
        // "like" x2 + "totally" = 3 fillers, but we're testing "like" specifically
        let likeFillers = events.filter {
            if case .fillerWord(let word) = $0.type { return word == "like" }
            return false
        }
        XCTAssertEqual(likeFillers.count, 2)
    }

    func testDetectsBasically() {
        let events = analyzer.analyzeText("basically it works basically fine")
        let fillers = events.filter { if case .fillerWord = $0.type { return true }; return false }
        XCTAssertEqual(fillers.count, 2)
    }

    func testDetectsAllSingleWordFillers() {
        let singleWordFillers = [
            "um", "uh", "uhh", "umm", "erm", "er",
            "like", "basically", "actually", "literally", "honestly",
            "so", "well", "anyway", "anyways",
            "just", "really", "very", "totally",
            "definitely", "absolutely", "obviously"
        ]
        for filler in singleWordFillers {
            let events = analyzer.analyzeText("I \(filler) went there")
            let fillerEvents = events.filter { if case .fillerWord = $0.type { return true }; return false }
            XCTAssertGreaterThanOrEqual(fillerEvents.count, 1, "Failed to detect filler: \(filler)")
        }
    }

    func testDetectsMultiWordFillers() {
        let multiWordFillers = [
            "you know", "i mean", "kind of", "sort of",
            "i guess", "i think", "i suppose"
        ]
        for filler in multiWordFillers {
            let events = analyzer.analyzeText("I was \(filler) going there")
            let fillerEvents = events.filter { if case .fillerWord = $0.type { return true }; return false }
            XCTAssertGreaterThanOrEqual(fillerEvents.count, 1, "Failed to detect multi-word filler: \(filler)")
        }
    }

    // MARK: - Hedging detection

    func testDetectsHedgingMaybe() {
        let events = analyzer.analyzeText("maybe we should try that")
        let hedging = events.filter { if case .hedging = $0.type { return true }; return false }
        XCTAssertEqual(hedging.count, 1)
    }

    func testDetectsHedgingPhrases() {
        let hedgingPhrases = [
            "i believe", "i feel like", "perhaps", "probably",
            "possibly", "somewhat", "not sure", "not certain",
            "might be", "could be", "may be",
            "in my opinion", "it seems like", "i don't know"
        ]
        for phrase in hedgingPhrases {
            let events = analyzer.analyzeText("well \(phrase) that is correct")
            let hedgingEvents = events.filter { if case .hedging = $0.type { return true }; return false }
            XCTAssertGreaterThanOrEqual(hedgingEvents.count, 1, "Failed to detect hedging: \(phrase)")
        }
    }

    // MARK: - Run-on detection

    func testDetectsRunOnSentence() {
        // 36+ words = run-on
        let words = (0..<36).map { "word\($0)" }.joined(separator: " ")
        let events = analyzer.analyzeText(words)
        let runOns = events.filter { if case .runOn = $0.type { return true }; return false }
        XCTAssertEqual(runOns.count, 1)
    }

    func testNoRunOnForShortSentence() {
        let events = analyzer.analyzeText("This is a short sentence.")
        let runOns = events.filter { if case .runOn = $0.type { return true }; return false }
        XCTAssertEqual(runOns.count, 0)
    }

    func testExactly35WordsIsNotRunOn() {
        let words = (0..<35).map { "word\($0)" }.joined(separator: " ")
        let events = analyzer.analyzeText(words)
        let runOns = events.filter { if case .runOn = $0.type { return true }; return false }
        XCTAssertEqual(runOns.count, 0)
    }

    // MARK: - No false positives

    func testNoEventsForCleanText() {
        let events = analyzer.analyzeText("The presentation went very smoothly today.")
        // "very" is a filler word, so we expect that but no hedging or run-on
        let hedging = events.filter { if case .hedging = $0.type { return true }; return false }
        let runOns = events.filter { if case .runOn = $0.type { return true }; return false }
        XCTAssertEqual(hedging.count, 0)
        XCTAssertEqual(runOns.count, 0)
    }
}

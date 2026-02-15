import AVFoundation
import Speech

final class SpeechTranscriber {
    var onPartialTranscript: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    private(set) var isTranscribing = false

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var cumulativeTranscript = ""

    static var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    static func requestAuthorization(completion: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization(completion)
    }

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func start() {
        guard !isTranscribing else { return }
        guard let recognizer, recognizer.isAvailable else {
            onError?(SpeechTranscriberError.unavailable)
            return
        }

        cumulativeTranscript = ""
        startRecognitionRequest()
    }

    func stop() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isTranscribing = false
    }

    /// Feed audio buffer from the shared AVAudioEngine tap
    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    // MARK: - Private

    private func startRecognitionRequest() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        recognitionRequest = request
        isTranscribing = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    if result.isFinal {
                        // Apple 1-min timeout hit — save cumulative and restart
                        self.cumulativeTranscript += (self.cumulativeTranscript.isEmpty ? "" : " ") + transcript
                        self.onPartialTranscript?(self.cumulativeTranscript)
                        self.restartRecognition()
                    } else {
                        let full = self.cumulativeTranscript.isEmpty
                            ? transcript
                            : self.cumulativeTranscript + " " + transcript
                        self.onPartialTranscript?(full)
                    }
                }
            }

            if let error, (error as NSError).code != 216 { // 216 = recognition cancelled
                DispatchQueue.main.async {
                    self.onError?(error)
                }
            }
        }
    }

    /// Auto-restart after Apple's ~1min speech recognition limit
    private func restartRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        guard isTranscribing else { return }
        startRecognitionRequest()
    }
}

enum SpeechTranscriberError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Speech recognition is not available on this device."
        }
    }
}

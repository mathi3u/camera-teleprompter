import AVFoundation
import Foundation

@Observable
final class AudioLevelMonitor {
    private(set) var currentLevel: Float = -160
    private(set) var isSpeaking: Bool = false

    var threshold: Float = -30
    var debounceInterval: TimeInterval = 0.3

    private var audioEngine: AVAudioEngine?
    private var isMonitoring = false
    private var lastSpeakingTime: Date?
    private var silenceTimer: Timer?

    /// Calculate RMS from a buffer of float samples
    static func rms(from buffer: UnsafePointer<Float>, count: Int) -> Float {
        guard count > 0 else { return 0 }
        var sumOfSquares: Float = 0
        for i in 0..<count {
            sumOfSquares += buffer[i] * buffer[i]
        }
        return sqrt(sumOfSquares / Float(count))
    }

    /// Convert linear RMS to decibels
    static func toDecibels(_ rms: Float) -> Float {
        guard rms > 0 else { return -160 }
        return 20 * log10(rms)
    }

    /// Accept externally-computed dB level (used by AudioPipelineController)
    func processLevel(db: Float) {
        currentLevel = db
        updateSpeakingState(db: db)
    }

    func start() {
        guard !isMonitoring else { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self,
                  let channelData = buffer.floatChannelData else { return }

            let frames = Int(buffer.frameLength)
            let rmsValue = Self.rms(from: channelData[0], count: frames)
            let db = Self.toDecibels(rmsValue)

            DispatchQueue.main.async {
                self.currentLevel = db
                self.updateSpeakingState(db: db)
            }
        }

        do {
            try engine.start()
            audioEngine = engine
            isMonitoring = true
        } catch {
            print("AudioLevelMonitor: Failed to start engine: \(error)")
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isMonitoring = false
        silenceTimer?.invalidate()
        silenceTimer = nil
        currentLevel = -160
        isSpeaking = false
    }

    private func updateSpeakingState(db: Float) {
        if db >= threshold {
            // Speaking detected
            lastSpeakingTime = Date()
            silenceTimer?.invalidate()
            silenceTimer = nil
            if !isSpeaking {
                isSpeaking = true
            }
        } else if isSpeaking, silenceTimer == nil {
            // Below threshold, start debounce timer
            silenceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
                self?.isSpeaking = false
                self?.silenceTimer = nil
            }
        }
    }
}

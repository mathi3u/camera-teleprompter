import AVFoundation
import Foundation

/// Owns a single AVAudioEngine and fans out its buffer to multiple consumers:
/// AudioLevelMonitor, SpeechTranscriber, and PitchDetector.
final class AudioPipelineController {
    private var audioEngine: AVAudioEngine?
    private(set) var isRunning = false

    private weak var levelMonitor: AudioLevelMonitor?
    private weak var transcriber: SpeechTranscriber?
    private var pitchTracker: RealTimePitchTracker?
    private var onPitch: ((Float) -> Void)?

    func configure(
        levelMonitor: AudioLevelMonitor,
        transcriber: SpeechTranscriber,
        pitchTracker: RealTimePitchTracker,
        onPitch: ((Float) -> Void)? = nil
    ) {
        self.levelMonitor = levelMonitor
        self.transcriber = transcriber
        self.pitchTracker = pitchTracker
        self.onPitch = onPitch
    }

    func start() {
        guard !isRunning else { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }

            // Fan out to level monitor
            if let channelData = buffer.floatChannelData {
                let frames = Int(buffer.frameLength)
                let rmsValue = AudioLevelMonitor.rms(from: channelData[0], count: frames)
                let db = AudioLevelMonitor.toDecibels(rmsValue)
                DispatchQueue.main.async {
                    self.levelMonitor?.processLevel(db: db)
                }
            }

            // Fan out to speech transcriber
            self.transcriber?.appendBuffer(buffer)

            // Fan out to pitch detector
            let pitch = PitchDetector.detectPitch(buffer: buffer, sampleRate: Float(format.sampleRate))
            if pitch > 0 {
                DispatchQueue.main.async {
                    self.pitchTracker?.addPitch(pitch)
                    self.onPitch?(pitch)
                }
            }
        }

        do {
            try engine.start()
            audioEngine = engine
            isRunning = true
        } catch {
            print("AudioPipelineController: Failed to start engine: \(error)")
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false
    }
}

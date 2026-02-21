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
    private var onLevel: ((Float) -> Void)?
    private var deviceChangeObserver: NSObjectProtocol?

    func configure(
        levelMonitor: AudioLevelMonitor,
        transcriber: SpeechTranscriber,
        pitchTracker: RealTimePitchTracker,
        onPitch: ((Float) -> Void)? = nil,
        onLevel: ((Float) -> Void)? = nil
    ) {
        self.levelMonitor = levelMonitor
        self.transcriber = transcriber
        self.pitchTracker = pitchTracker
        self.onPitch = onPitch
        self.onLevel = onLevel
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
                    self.onLevel?(db)
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
            observeDeviceChanges()
        } catch {
            print("AudioPipelineController: Failed to start engine: \(error)")
        }
    }

    private func observeDeviceChanges() {
        deviceChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { [weak self] _ in
            self?.restart()
        }
    }

    private func restart() {
        guard isRunning else { return }
        // Stop engine
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false
        // Restart transcriber so it creates a fresh recognition request
        transcriber?.stop()
        // Brief delay to let the new device settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.transcriber?.start()
            self?.start()
        }
    }

    func stop() {
        if let observer = deviceChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceChangeObserver = nil
        }
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false
    }
}

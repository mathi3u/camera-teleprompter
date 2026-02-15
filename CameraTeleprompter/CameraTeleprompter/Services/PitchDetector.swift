import AVFoundation
import Foundation

/// Autocorrelation-based pitch detection ported from audioAnalysis.ts
enum PitchDetector {

    /// Detect fundamental frequency from a float buffer using autocorrelation
    /// Returns 0 if no pitch detected (silence or too noisy)
    static func detectPitch(buffer: [Float], sampleRate: Float) -> Float {
        let minFreq: Float = 50   // Hz
        let maxFreq: Float = 500  // Hz
        let minPeriod = Int(sampleRate / maxFreq)
        let maxPeriod = Int(sampleRate / minFreq)

        guard buffer.count > maxPeriod else { return 0 }

        // Check if there's enough signal (RMS threshold)
        var sumOfSquares: Float = 0
        for sample in buffer {
            sumOfSquares += sample * sample
        }
        let rms = sqrt(sumOfSquares / Float(buffer.count))
        if rms < 0.01 { return 0 }

        // Compute normalized autocorrelation for all candidate periods
        let effectiveMax = min(maxPeriod, buffer.count - 1)
        var correlations = [Float](repeating: 0, count: effectiveMax + 1)
        var globalMax: Float = 0

        for period in minPeriod...effectiveMax {
            var correlation: Float = 0
            let limit = buffer.count - period
            for i in 0..<limit {
                correlation += buffer[i] * buffer[i + period]
            }
            correlation /= Float(limit)
            correlations[period] = correlation
            if correlation > globalMax {
                globalMax = correlation
            }
        }

        guard globalMax > 0.01 else { return 0 }

        // Find first peak above 90% of global max (picks fundamental, not subharmonic)
        let threshold = globalMax * 0.9
        for period in minPeriod...effectiveMax {
            let c = correlations[period]
            if c >= threshold {
                // Verify it's a local maximum
                let prev = period > minPeriod ? correlations[period - 1] : 0
                let next = period < effectiveMax ? correlations[period + 1] : 0
                if c >= prev && c >= next {
                    return sampleRate / Float(period)
                }
            }
        }

        return 0
    }

    /// Process an AVAudioPCMBuffer and detect pitch
    static func detectPitch(buffer: AVAudioPCMBuffer, sampleRate: Float) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        let pointer = channelData[0]
        let samples = Array(UnsafeBufferPointer(start: pointer, count: frames))
        return detectPitch(buffer: samples, sampleRate: sampleRate)
    }
}

/// Tracks pitch over time and detects uptalk (rising intonation at sentence ends)
@Observable
final class RealTimePitchTracker {
    private(set) var uptalkCount: Int = 0
    private(set) var sentenceCount: Int = 0
    private(set) var currentPitch: Float = 0

    private var recentPitches: [Float] = []
    private static let windowSize = 10 // frames to analyze for uptalk

    func addPitch(_ pitch: Float) {
        guard pitch > 0 else { return }
        currentPitch = pitch
        recentPitches.append(pitch)
        // Keep a reasonable window
        if recentPitches.count > 50 {
            recentPitches.removeFirst()
        }
    }

    /// Call when a sentence boundary is detected
    func markSentenceEnd() {
        sentenceCount += 1

        let window = min(Self.windowSize, recentPitches.count)
        guard window >= 4 else { return }

        let pitchWindow = Array(recentPitches.suffix(window))
        let third = window / 3
        guard third > 0 else { return }

        let firstThird = Array(pitchWindow.prefix(third))
        let lastThird = Array(pitchWindow.suffix(third))

        let avgFirst = firstThird.reduce(0, +) / Float(firstThird.count)
        let avgLast = lastThird.reduce(0, +) / Float(lastThird.count)

        // Rising by more than 15% indicates uptalk
        if avgLast > avgFirst * 1.15 {
            uptalkCount += 1
        }
    }

    func reset() {
        uptalkCount = 0
        sentenceCount = 0
        currentPitch = 0
        recentPitches = []
    }
}

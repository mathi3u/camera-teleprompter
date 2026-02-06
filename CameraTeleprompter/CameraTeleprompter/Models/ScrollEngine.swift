import Foundation

@Observable
final class ScrollEngine {
    /// Current scroll offset in points (increases as text scrolls up)
    private(set) var offset: CGFloat = 0

    /// Scroll speed in points per second (clamped to 10...200)
    var speed: CGFloat = 60

    private func clampSpeed() {
        speed = max(10, min(200, speed))
    }

    /// Whether scrolling is currently active
    private(set) var isScrolling: Bool = false

    /// Whether scrolling is paused (by voice silence or user)
    private(set) var isPaused: Bool = false

    /// Total scrollable height (set from view measurement)
    var contentHeight: CGFloat = 0

    /// Visible height of the scroll area
    var viewportHeight: CGFloat = 0

    /// Maximum offset (content scrolled fully past viewport)
    var maxOffset: CGFloat {
        max(0, contentHeight - viewportHeight)
    }

    private var lastTickTime: TimeInterval?

    func start() {
        offset = 0
        isScrolling = true
        isPaused = false
        lastTickTime = nil
    }

    func stop() {
        isScrolling = false
        isPaused = false
        lastTickTime = nil
    }

    func pause() {
        guard isScrolling else { return }
        isPaused = true
    }

    func resume() {
        guard isScrolling else { return }
        isPaused = false
        lastTickTime = nil
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    /// Call once per frame with current timestamp
    func tick(now: TimeInterval) {
        guard isScrolling, !isPaused else {
            lastTickTime = nil
            return
        }

        if let last = lastTickTime {
            let dt = now - last
            // Clamp dt to avoid jumps after long pauses
            let clampedDt = min(dt, 0.1)
            offset += speed * CGFloat(clampedDt)
            offset = min(offset, maxOffset)
        }
        lastTickTime = now
    }

    /// Adjust speed up/down by increment
    func adjustSpeed(by delta: CGFloat) {
        speed += delta
        clampSpeed()
    }

    /// Set speed with clamping
    func setSpeed(_ newSpeed: CGFloat) {
        speed = newSpeed
        clampSpeed()
    }

    /// Reset offset to beginning
    func reset() {
        offset = 0
        lastTickTime = nil
    }

    /// Whether the scroll has reached the end
    var isAtEnd: Bool {
        contentHeight > 0 && offset >= maxOffset
    }
}

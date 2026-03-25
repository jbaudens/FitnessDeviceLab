import Foundation
import Combine
import Observation

/// A timer dedicated to a workout session, managing 1Hz ticks and accumulated duration.
@Observable
public class SessionTimer {
    public private(set) var isActive: Bool = false
    public private(set) var isPaused: Bool = false
    
    /// Total elapsed time in the session (excluding pauses).
    public private(set) var elapsedTime: TimeInterval = 0
    
    /// Triggered every 1 second when the timer is active and not paused.
    public var onTick: (() -> Void)?
    
    private var timerCancellable: AnyCancellable?
    
    public init() {}
    
    public func start() {
        guard !isActive else { return }
        isActive = true
        isPaused = true // Start in paused state (pulse only, no counting)
        elapsedTime = 0
        setupTimer()
    }
    
    public func pause() {
        guard isActive, !isPaused else { return }
        isPaused = true
    }
    
    public func resume() {
        guard isActive, isPaused else { return }
        isPaused = false
    }
    
    public func stop() {
        isActive = false
        isPaused = false
        stopTimer()
    }
    
    public func reset() {
        isActive = false
        isPaused = false
        elapsedTime = 0
        stopTimer()
    }
    
    /// For testing purposes: manually triggers a tick
    public func advanceOneSecond() {
        guard isActive else { return }
        tick()
    }
    
    private func setupTimer() {
        stopTimer() // Ensure no double timers
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        if !isPaused {
            elapsedTime += 1.0
        }
        onTick?()
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

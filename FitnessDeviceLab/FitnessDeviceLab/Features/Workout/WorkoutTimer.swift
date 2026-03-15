import Foundation
import Combine
import Observation

@Observable
public class WorkoutTimer {
    public private(set) var isActive: Bool = false
    public private(set) var isPaused: Bool = false
    
    /// Triggered every 1 second when the timer is active and not paused.
    public var onTick: (() -> Void)?
    
    private var timerCancellable: AnyCancellable?
    
    public init() {}
    
    public func start() {
        guard !isActive else { return }
        isActive = true
        isPaused = false
        setupTimer()
    }
    
    public func pause() {
        guard isActive, !isPaused else { return }
        isPaused = true
        stopTimer()
    }
    
    public func resume() {
        guard isActive, isPaused else { return }
        isPaused = false
        setupTimer()
    }
    
    public func stop() {
        isActive = false
        isPaused = false
        stopTimer()
    }
    
    /// For testing purposes: manually triggers a tick
    public func advanceOneSecond() {
        onTick?()
    }
    
    private func setupTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.onTick?()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

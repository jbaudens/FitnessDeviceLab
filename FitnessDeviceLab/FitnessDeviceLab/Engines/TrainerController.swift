import Foundation

/// Manages commands sent to a smart trainer, tracking state to avoid redundant Bluetooth traffic.
public class TrainerController {
    /// The actual hardware/simulated trainer being controlled.
    public var trainer: ControllableTrainer? {
        didSet {
            // Reset tracking when trainer changes
            lastSentTargetPower = nil
            lastSentResistanceLevel = nil
        }
    }
    
    private var lastSentTargetPower: Int?
    private var lastSentResistanceLevel: Double?
    
    public init(trainer: ControllableTrainer? = nil) {
        self.trainer = trainer
    }
    
    /// Sets the trainer to a specific wattage (ERG mode).
    public func setTargetPower(_ watts: Int) {
        guard let trainer = trainer else { return }
        
        if lastSentTargetPower != watts {
            trainer.setTargetPower(watts)
            lastSentTargetPower = watts
            lastSentResistanceLevel = nil // Clear resistance tracking since we are in ERG
        }
    }
    
    /// Sets the trainer to a manual resistance level (0-100).
    public func setResistanceLevel(_ level: Double) {
        guard let trainer = trainer else { return }
        
        if lastSentResistanceLevel != level || lastSentTargetPower != nil {
            trainer.setResistanceLevel(level)
            lastSentResistanceLevel = level
            lastSentTargetPower = nil // Clear target power tracking
        }
    }
    
    /// Resets the internal state tracking.
    public func reset() {
        lastSentTargetPower = nil
        lastSentResistanceLevel = nil
    }
}

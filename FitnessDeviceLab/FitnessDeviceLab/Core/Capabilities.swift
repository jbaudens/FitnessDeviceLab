import Foundation
import Observation

/// A role-based adaptor that exposes only Heart Rate capabilities of a peripheral.
@Observable
public class HeartRateSensor: HeartRateProviding, Hashable {
    private let peripheral: any SensorPeripheral
    
    public var heartRate: Int? { peripheral.heartRate }
    public var latestRRIntervals: [Double] {
        get { peripheral.latestRRIntervals }
        set { peripheral.latestRRIntervals = newValue }
    }
    
    public var id: UUID { peripheral.id }
    public var name: String { peripheral.name }
    public var manufacturerName: String? { peripheral.manufacturerName }
    public var modelNumber: String? { peripheral.modelNumber }
    
    public init?(peripheral: any SensorPeripheral) {
        guard peripheral.capabilities.contains(.heartRate) else { return nil }
        self.peripheral = peripheral
    }
    
    public static func == (lhs: HeartRateSensor, rhs: HeartRateSensor) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A role-based adaptor that exposes only Power capabilities of a peripheral.
@Observable
public class PowerSensor: PowerProviding, Hashable {
    private let peripheral: any SensorPeripheral
    
    public var cyclingPower: Int? { peripheral.cyclingPower }
    public var powerBalance: Double? { peripheral.powerBalance }
    
    public var id: UUID { peripheral.id }
    public var name: String { peripheral.name }
    public var manufacturerName: String? { peripheral.manufacturerName }
    public var modelNumber: String? { peripheral.modelNumber }
    
    public init?(peripheral: any SensorPeripheral) {
        guard peripheral.capabilities.contains(.cyclingPower) || 
              peripheral.capabilities.contains(.fitnessMachine) else { return nil }
        self.peripheral = peripheral
    }
    
    public static func == (lhs: PowerSensor, rhs: PowerSensor) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A role-based adaptor that exposes only Cadence capabilities of a peripheral.
@Observable
public class CadenceSensor: CadenceProviding, Hashable {
    private let peripheral: any SensorPeripheral
    
    public var cadence: Int? { peripheral.cadence }
    
    public var id: UUID { peripheral.id }
    public var name: String { peripheral.name }
    
    public init?(peripheral: any SensorPeripheral) {
        guard peripheral.capabilities.contains(.cyclingPower) || 
              peripheral.capabilities.contains(.fitnessMachine) ||
              peripheral.cadence != nil else { return nil }
        self.peripheral = peripheral
    }
    
    public static func == (lhs: CadenceSensor, rhs: CadenceSensor) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A role-based adaptor that exposes only controllable (ERG/Resistance) capabilities of a peripheral.
@Observable
public class ControllableTrainer: ResistanceControllable, PowerProviding, CadenceProviding, Hashable {
    private let peripheral: any SensorPeripheral

    public var cyclingPower: Int? { peripheral.cyclingPower }
    public var cadence: Int? { peripheral.cadence }
    public var powerBalance: Double? { peripheral.powerBalance }

    public var id: UUID { peripheral.id }
    public var name: String { peripheral.name }
    public var manufacturerName: String? { peripheral.manufacturerName }
    public var modelNumber: String? { peripheral.modelNumber }

    
    public var supportsPowerControl: Bool { peripheral.supportsPowerControl }
    public var supportsResistanceControl: Bool { peripheral.supportsResistanceControl }
    
    public init?(peripheral: any SensorPeripheral) {
        guard peripheral.capabilities.contains(.fitnessMachine) else { return nil }
        self.peripheral = peripheral
    }
    
    public func setTargetPower(_ watts: Int) {
        peripheral.setTargetPower(watts)
    }
    
    public func setResistanceLevel(_ level: Double) {
        peripheral.setResistanceLevel(level)
    }
    
    public static func == (lhs: ControllableTrainer, rhs: ControllableTrainer) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

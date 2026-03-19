import Foundation
import SwiftUI
import Observation
import CoreBluetooth

// MARK: - Core Capability Protocols

public protocol HeartRateProviding: AnyObject, Observation.Observable {
    var id: UUID { get }
    var name: String { get }
    var heartRate: Int? { get }
    var latestRRIntervals: [Double] { get set }
}

public protocol PowerProviding: AnyObject, Observation.Observable {
    var id: UUID { get }
    var name: String { get }
    var cyclingPower: Int? { get }
    var powerBalance: Double? { get }
}

public protocol CadenceProviding: AnyObject, Observation.Observable {
    var id: UUID { get }
    var name: String { get }
    var cadence: Int? { get }
}

public protocol ResistanceControllable: AnyObject, Observation.Observable {
    var id: UUID { get }
    var name: String { get }
    func setTargetPower(_ watts: Int)
    func setResistanceLevel(_ level: Double)
}

// MARK: - Base Peripheral Protocol

public protocol SensorPeripheral: AnyObject, Observation.Observable {
    var id: UUID { get }
    var name: String { get }
    var isConnected: Bool { get }
    
    var manufacturerName: String? { get }
    var modelNumber: String? { get }
    
    var capabilities: Set<DeviceCapability> { get }
    
    var supportsPowerControl: Bool { get }
    
    var heartRate: Int? { get }
    var cyclingPower: Int? { get }
    var cadence: Int? { get }
    var powerBalance: Double? { get }
    var latestRRIntervals: [Double] { get set }
    
    func setTargetPower(_ watts: Int)
    func setResistanceLevel(_ level: Double)
}

// MARK: - Internal Bluetooth Driver Protocol

public protocol BluetoothDriver: AnyObject {
    var state: CBManagerState { get }
    var isScanning: Bool { get }
    var peripherals: [any SensorPeripheral] { get }
    
    func startScanning()
    func stopScanning()
    func connect(peripheral: any SensorPeripheral)
    func disconnect(peripheral: any SensorPeripheral)
    
    var onUpdate: (() -> Void)? { get set }
}

// MARK: - Location Protocol

public protocol LocationProvider: AnyObject {
    var currentAltitude: Double? { get }
}

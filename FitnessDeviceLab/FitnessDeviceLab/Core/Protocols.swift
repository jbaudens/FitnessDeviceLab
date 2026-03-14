import Foundation
import Combine

public protocol SensorPeripheral: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var isConnected: Bool { get }
    
    var heartRate: Int? { get }
    var cyclingPower: Int? { get }
    var cadence: Int? { get }
    var powerBalance: Double? { get }
    
    var latestRRIntervals: [Double] { get }
    var capabilities: Set<DeviceCapability> { get }
    
    func setTargetPower(_ watts: Int)
    func setResistanceLevel(_ level: Double)
}

public protocol BluetoothProvider: AnyObject {
    var isScanning: Bool { get }
    var peripherals: [DiscoveredPeripheral] { get }
    
    func startScanning()
    func stopScanning()
    func connect(peripheral: DiscoveredPeripheral)
    func disconnect(peripheral: DiscoveredPeripheral)
}

import Foundation
import Observation

@Observable
@MainActor
public class DevicesViewModel {
    public var bluetoothManager: BluetoothManager
    
    public init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    // MARK: - Proxy Properties
    
    public var peripherals: [any SensorPeripheral] {
        bluetoothManager.peripherals
    }
    
    public var isScanning: Bool {
        bluetoothManager.isScanning
    }
    
    // MARK: - Role-Specific Adaptors
    
    public func hrSensor(for peripheral: any SensorPeripheral) -> HeartRateSensor? {
        HeartRateSensor(peripheral: peripheral)
    }
    
    public func powerSensor(for peripheral: any SensorPeripheral) -> PowerSensor? {
        PowerSensor(peripheral: peripheral)
    }
    
    public func cadenceSensor(for peripheral: any SensorPeripheral) -> CadenceSensor? {
        CadenceSensor(peripheral: peripheral)
    }
    
    public func controllableTrainer(for peripheral: any SensorPeripheral) -> ControllableTrainer? {
        ControllableTrainer(peripheral: peripheral)
    }
    
    // MARK: - Actions
    
    public func addSimulatedDevice(name: String) {
        bluetoothManager.addSimulatedDevice(name: name)
    }
    
    public func removeSimulatedDevice(id: UUID) {
        bluetoothManager.removeSimulatedDevice(id: id)
    }
    
    public func startScanning() {
        bluetoothManager.startScanning()
    }
    
    public func stopScanning() {
        bluetoothManager.stopScanning()
    }
    
    public func toggleConnection(for peripheral: any SensorPeripheral) {
        if peripheral.isConnected {
            bluetoothManager.disconnect(peripheral: peripheral)
        } else {
            bluetoothManager.connect(peripheral: peripheral)
        }
    }
}

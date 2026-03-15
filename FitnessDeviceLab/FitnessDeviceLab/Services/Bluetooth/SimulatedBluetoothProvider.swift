import Foundation
import Observation

@Observable @MainActor
public class SimulatedBluetoothProvider: BluetoothProvider {
    public var isScanning = false
    public var peripherals: [any SensorPeripheral] = []
    
    public init() {
        self.peripherals = [
            SimulatedPeripheral(name: "Virtual Bike (Smart)"),
            SimulatedPeripheral(name: "Fake HR Strap")
        ]
    }
    
    public func startScanning() {
        isScanning = true
        // In simulation, we already have "discovered" devices
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isScanning = false
        }
    }
    
    public func stopScanning() {
        isScanning = false
    }
    
    public func connect(peripheral: any SensorPeripheral) {
        if let sim = peripheral as? SimulatedPeripheral {
            sim.isConnected = true
        }
    }
    
    public func disconnect(peripheral: any SensorPeripheral) {
        if let sim = peripheral as? SimulatedPeripheral {
            sim.isConnected = false
        }
    }
}

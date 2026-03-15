import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
public class DevicesViewModel {
    public var bluetoothProvider: any BluetoothProvider
    
    public init(bluetoothProvider: any BluetoothProvider) {
        self.bluetoothProvider = bluetoothProvider
    }
    
    // MARK: - Categorized Devices
    
    public var hrDevices: [any SensorPeripheral] {
        bluetoothProvider.peripherals.filter { $0.capabilities.contains(.heartRate) }
    }
    
    public var powerDevices: [any SensorPeripheral] {
        bluetoothProvider.peripherals.filter { $0.capabilities.contains(.cyclingPower) }
    }
    
    public var trainerDevices: [any SensorPeripheral] {
        bluetoothProvider.peripherals.filter { $0.capabilities.contains(.fitnessMachine) }
    }
    
    public var otherDevices: [any SensorPeripheral] {
        bluetoothProvider.peripherals.filter { $0.capabilities.isEmpty }
    }
    
    // MARK: - Actions
    
    public func startScanning() {
        bluetoothProvider.startScanning()
    }
    
    public func stopScanning() {
        bluetoothProvider.stopScanning()
    }
    
    public func toggleConnection(for peripheral: any SensorPeripheral) {
        if peripheral.isConnected {
            bluetoothProvider.disconnect(peripheral: peripheral)
        } else {
            bluetoothProvider.connect(peripheral: peripheral)
        }
    }
}

import Foundation
import Observation
import CoreBluetooth
import AudioToolbox

public class BluetoothManager: NSObject, Observation.Observable, BluetoothProvider {
    public static let shared = BluetoothManager()
    
    private let centralManager: CBCentralManager
    
    public var isScanning = false
    public var peripherals: [any SensorPeripheral] = []
    
    private let serviceUUIDs = [
        CBUUID(string: "180D"), // Heart Rate
        CBUUID(string: "1818"), // Cycling Power
        CBUUID(string: "1826"), // Fitness Machine
        CBUUID(string: "1816")  // Cycling Speed and Cadence
    ]

    private override init() {
        let manager = CBCentralManager(delegate: nil, queue: nil)
        self.centralManager = manager
        super.init()
        manager.delegate = self
    }

    public func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        peripherals.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    public func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    public func connect(peripheral: any SensorPeripheral) {
        if let disc = peripheral as? DiscoveredPeripheral {
            centralManager.connect(disc.peripheral, options: nil)
        }
    }

    public func disconnect(peripheral: any SensorPeripheral) {
        if let disc = peripheral as? DiscoveredPeripheral {
            centralManager.cancelPeripheralConnection(disc.peripheral)
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            isScanning = false
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        MainActor.assumeIsolated {
            var discoveredCapabilities: Set<DeviceCapability> = []
            if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                for uuid in serviceUUIDs {
                    if uuid == CBUUID(string: "180D") { discoveredCapabilities.insert(.heartRate) }
                    if uuid == CBUUID(string: "1818") { discoveredCapabilities.insert(.cyclingPower) }
                    if uuid == CBUUID(string: "1826") { discoveredCapabilities.insert(.fitnessMachine) }
                }
            }
            
            if let existing = self.peripherals.first(where: { $0.id == peripheral.identifier }) as? DiscoveredPeripheral {
                existing.rssi = RSSI
                existing.lastSeen = Date()
                if let name = peripheral.name, existing.name == "Unknown Device" {
                    existing.name = name
                }
                existing.capabilities.formUnion(discoveredCapabilities)
            } else {
                let discovered = DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI)
                discovered.capabilities = discoveredCapabilities
                discovered.lastSeen = Date()
                self.peripherals.append(discovered)
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) as? DiscoveredPeripheral {
                discovered.isConnected = true
                discovered.discoverServices()
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        MainActor.assumeIsolated {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) as? DiscoveredPeripheral {
                let wasConnected = discovered.isConnected
                
                discovered.isConnected = false
                discovered.heartRate = nil
                discovered.cyclingPower = nil
                discovered.cadence = nil
                discovered.isControlRequested = false
                discovered.controlPointCharacteristic = nil
                
                if wasConnected {
                    AudioServicesPlaySystemSound(1006) 
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }
}

import Foundation
import CoreBluetooth
import Combine
import AudioToolbox

public class BluetoothManager: NSObject, ObservableObject, BluetoothProvider {
    public static let shared = BluetoothManager()
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    private var centralManager: CBCentralManager!
    
    @Published public var isScanning = false
    @Published public var peripherals: [DiscoveredPeripheral] = []
    
    private var cleanupTimer: AnyCancellable?
    
    private let serviceUUIDs = [
        CBUUID(string: "180D"), // Heart Rate
        CBUUID(string: "1818"), // Cycling Power
        CBUUID(string: "1826")  // Fitness Machine
    ]

    public func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        peripherals.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        cleanupTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let now = Date()
                self?.peripherals.removeAll { !$0.isConnected && now.timeIntervalSince($0.lastSeen) > 15 }
            }
    }

    public func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        cleanupTimer?.cancel()
        cleanupTimer = nil
    }

    public func connect(peripheral: DiscoveredPeripheral) {
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    public func disconnect(peripheral: DiscoveredPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral.peripheral)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Ready to scan
        } else {
            isScanning = false
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        DispatchQueue.main.async {
            var discoveredCapabilities: Set<DeviceCapability> = []
            if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                for uuid in serviceUUIDs {
                    if uuid == CBUUID(string: "180D") { discoveredCapabilities.insert(.heartRate) }
                    if uuid == CBUUID(string: "1818") { discoveredCapabilities.insert(.cyclingPower) }
                    if uuid == CBUUID(string: "1826") { discoveredCapabilities.insert(.fitnessMachine) }
                }
            }
            
            if let existing = self.peripherals.first(where: { $0.id == peripheral.identifier }) {
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
        DispatchQueue.main.async {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) {
                discovered.isConnected = true
                discovered.discoverServices()
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) {
                let wasConnected = discovered.isConnected
                
                discovered.isConnected = false
                discovered.heartRate = nil
                discovered.cyclingPower = nil
                discovered.cadence = nil
                discovered.isControlRequested = false
                discovered.controlPointCharacteristic = nil
                
                if wasConnected {
                    // Play disconnect sound
                    AudioServicesPlaySystemSound(1006) // Standard alert beep
                    
                    // Attempt auto-reconnect
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }
}

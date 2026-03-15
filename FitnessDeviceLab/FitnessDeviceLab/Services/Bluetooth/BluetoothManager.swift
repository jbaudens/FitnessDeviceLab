import Foundation
import Observation
import CoreBluetooth
import AudioToolbox

@Observable
public class BluetoothManager: NSObject {
    public static let shared = BluetoothManager()
    
    // MARK: - Observable State for UI
    public var state: CBManagerState = .unknown
    public var isScanning = false
    
    // Changed to a stored property so @Observable can track changes effectively
    public var peripherals: [any SensorPeripheral] = []
    
    // MARK: - Internal State
    private let realDriver: RealBluetoothDriver
    private var simulatedPeripherals: [SimulatedPeripheral] = []
    
    private override init() {
        let rd = RealBluetoothDriver()
        self.realDriver = rd
        super.init()
        
        // Link the real driver's state to our orchestrator
        realDriver.onUpdate = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.state = self.realDriver.state
                self.isScanning = self.realDriver.isScanning
                self.refreshCombinedPeripherals()
            }
        }
        
        // Initial sync
        self.state = realDriver.state
        self.isScanning = realDriver.isScanning
        self.refreshCombinedPeripherals()
    }
    
    // MARK: - Internal Helpers
    
    private func refreshCombinedPeripherals() {
        // We update the stored property explicitly to trigger UI refresh
        self.peripherals = realDriver.peripherals + simulatedPeripherals
    }
    
    // MARK: - Simulation Controls
    
    public func addSimulatedDevice(name: String) {
        let sim = SimulatedPeripheral(name: name)
        simulatedPeripherals.append(sim)
        refreshCombinedPeripherals()
    }
    
    public func removeSimulatedDevice(id: UUID) {
        simulatedPeripherals.removeAll { $0.id == id }
        refreshCombinedPeripherals()
    }
    
    // MARK: - Standard Actions
    
    public func startScanning() {
        realDriver.startScanning()
    }
    
    public func stopScanning() {
        realDriver.stopScanning()
    }
    
    public func connect(peripheral: any SensorPeripheral) {
        if let sim = peripheral as? SimulatedPeripheral {
            sim.isConnected = true
            refreshCombinedPeripherals()
        } else {
            realDriver.connect(peripheral: peripheral)
        }
    }
    
    public func disconnect(peripheral: any SensorPeripheral) {
        if let sim = peripheral as? SimulatedPeripheral {
            sim.isConnected = false
            refreshCombinedPeripherals()
        } else {
            realDriver.disconnect(peripheral: peripheral)
        }
    }
}

// MARK: - Real Bluetooth Driver Implementation

internal class RealBluetoothDriver: NSObject, CBCentralManagerDelegate {
    var state: CBManagerState = .unknown
    var isScanning = false
    var peripherals: [any SensorPeripheral] = []
    var onUpdate: (() -> Void)?
    
    private var centralManager: CBCentralManager!
    private var pendingScan = false
    
    private let serviceUUIDs = [
        CBUUID(string: "180D"), CBUUID(string: "1818"), 
        CBUUID(string: "1826"), CBUUID(string: "1816")
    ]
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        self.state = centralManager.state
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            peripherals.removeAll { !$0.isConnected }
            isScanning = true
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            onUpdate?()
        } else {
            pendingScan = true
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        pendingScan = false
        onUpdate?()
    }
    
    func connect(peripheral: any SensorPeripheral) {
        if let disc = peripheral as? DiscoveredPeripheral {
            centralManager.connect(disc.peripheral, options: nil)
        }
    }
    
    func disconnect(peripheral: any SensorPeripheral) {
        if let disc = peripheral as? DiscoveredPeripheral {
            centralManager.cancelPeripheralConnection(disc.peripheral)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        if state == .poweredOn && pendingScan {
            startScanning()
            pendingScan = false
        } else if state != .poweredOn {
            isScanning = false
        }
        onUpdate?()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var discoveredCapabilities: Set<DeviceCapability> = []
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for uuid in serviceUUIDs {
                if uuid == CBUUID(string: "180D") { discoveredCapabilities.insert(.heartRate) }
                if uuid == CBUUID(string: "1818") { discoveredCapabilities.insert(.cyclingPower) }
                if uuid == CBUUID(string: "1826") { discoveredCapabilities.insert(.fitnessMachine) }
                if uuid == CBUUID(string: "1816") { discoveredCapabilities.insert(.cadence) }
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
        onUpdate?()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) as? DiscoveredPeripheral {
            discovered.isConnected = true
            discovered.discoverServices()
        }
        onUpdate?()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) as? DiscoveredPeripheral {
            let wasConnected = discovered.isConnected
            discovered.isConnected = false
            if wasConnected {
                AudioServicesPlaySystemSound(1006)
                central.connect(peripheral, options: nil)
            }
        }
        onUpdate?()
    }
}

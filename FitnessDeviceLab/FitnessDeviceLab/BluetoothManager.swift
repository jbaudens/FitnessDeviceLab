import Foundation
import CoreBluetooth
import Combine
import AudioToolbox

nonisolated enum DeviceCapability: String, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case cyclingPower = "Power Meter"
    case fitnessMachine = "Smart Trainer"
    
    var id: String { rawValue }
}

nonisolated public struct TimeSeriesDataPoint: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp = Date()
    public let value: Double
    
    public init(value: Double) {
        self.value = value
    }
}

class DiscoveredPeripheral: NSObject, Identifiable, ObservableObject {
    let id: UUID
    let peripheral: CBPeripheral
    
    @Published var name: String
    @Published var rssi: NSNumber
    @Published var isConnected: Bool = false
    
    // Static Data
    @Published var manufacturerName: String?
    @Published var modelNumber: String?
    @Published var firmwareRevision: String?
    
    // Dynamic Data
    @Published var heartRate: Int?
    @Published var cyclingPower: Int?
    @Published var cadence: Int?
    @Published var batteryLevel: Int?
    
    // Cadence State
    private var lastCrankRevs: Int?
    private var lastCrankTime: Int?
    @Published var powerBalance: Double? // 0.0 to 100.0% (Left)
    
    // Capabilities
    @Published var capabilities: Set<DeviceCapability> = []
    
    // Connectivity State
    @Published var lastSeen: Date = Date()
    
    // Debug Data
    @Published var rawDataHex: String?
    
    // Latest RR Intervals (for external consumption)
    @Published var latestRRIntervals: [Double] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(peripheral: CBPeripheral, rssi: NSNumber) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Device"
        self.rssi = rssi
        super.init()
        self.peripheral.delegate = self
    }
}

extension DiscoveredPeripheral: CBPeripheralDelegate {
    // Standard Service UUIDs
    private static let heartRateServiceUUID = CBUUID(string: "180D")
    private static let cyclingPowerServiceUUID = CBUUID(string: "1818")
    private static let fitnessMachineServiceUUID = CBUUID(string: "1826")
    private static let deviceInfoServiceUUID = CBUUID(string: "180A")
    private static let batteryServiceUUID = CBUUID(string: "180F")
    
    // Standard Characteristic UUIDs
    private static let heartRateMeasurementUUID = CBUUID(string: "2A37")
    private static let cyclingPowerMeasurementUUID = CBUUID(string: "2A63")
    private static let indoorBikeDataUUID = CBUUID(string: "2AD2")
    
    private static let manufacturerNameUUID = CBUUID(string: "2A29")
    private static let modelNumberUUID = CBUUID(string: "2A24")
    private static let firmwareRevisionUUID = CBUUID(string: "2A26")
    private static let batteryLevelUUID = CBUUID(string: "2A19")
    
    func discoverServices() {
        peripheral.discoverServices([
            Self.heartRateServiceUUID,
            Self.cyclingPowerServiceUUID,
            Self.fitnessMachineServiceUUID,
            Self.deviceInfoServiceUUID,
            Self.batteryServiceUUID
        ])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            DispatchQueue.main.async {
                if service.uuid == Self.heartRateServiceUUID { self.capabilities.insert(.heartRate) }
                if service.uuid == Self.cyclingPowerServiceUUID { self.capabilities.insert(.cyclingPower) }
                if service.uuid == Self.fitnessMachineServiceUUID { self.capabilities.insert(.fitnessMachine) }
            }
            switch service.uuid {
            case Self.heartRateServiceUUID:
                peripheral.discoverCharacteristics([Self.heartRateMeasurementUUID], for: service)
            case Self.cyclingPowerServiceUUID:
                peripheral.discoverCharacteristics([Self.cyclingPowerMeasurementUUID], for: service)
            case Self.fitnessMachineServiceUUID:
                peripheral.discoverCharacteristics([Self.indoorBikeDataUUID], for: service)
            case Self.deviceInfoServiceUUID:
                peripheral.discoverCharacteristics([Self.manufacturerNameUUID, Self.modelNumberUUID, Self.firmwareRevisionUUID], for: service)
            case Self.batteryServiceUUID:
                peripheral.discoverCharacteristics([Self.batteryLevelUUID], for: service)
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        DispatchQueue.main.async {
            self.rawDataHex = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
            
            switch characteristic.uuid {
            case Self.heartRateMeasurementUUID:
                let (hr, rr) = self.parseHeartRate(data: data)
                self.heartRate = hr
                if !rr.isEmpty {
                    self.latestRRIntervals = rr
                }
            case Self.cyclingPowerMeasurementUUID:
                let (power, cadence, balance) = self.parseCyclingPower(data: data)
                if let power = power { self.cyclingPower = power }
                if let cadence = cadence { self.cadence = cadence }
                if let balance = balance { self.powerBalance = balance }
            case Self.indoorBikeDataUUID:
                let (power, cadence) = self.parseIndoorBikeData(data: data)
                if let power = power { self.cyclingPower = power }
                if let cadence = cadence { self.cadence = cadence }
            case Self.manufacturerNameUUID:
                self.manufacturerName = String(data: data, encoding: .utf8)
            case Self.modelNumberUUID:
                self.modelNumber = String(data: data, encoding: .utf8)
            case Self.firmwareRevisionUUID:
                self.firmwareRevision = String(data: data, encoding: .utf8)
            case Self.batteryLevelUUID:
                self.batteryLevel = Int(data[0])
            default:
                break
            }
        }
    }
    
    private func parseHeartRate(data: Data) -> (Int?, [Double]) {
        guard data.count > 1 else { return (nil, []) }
        let flags = data[0]
        let isUInt16 = (flags & 0x01) != 0
        let rrPresent = (flags & 0x10) != 0
        
        var hr: Int?
        var offset = 1
        
        if isUInt16 && data.count > 2 {
            hr = Int(data[1]) | (Int(data[2]) << 8)
            offset += 2
        } else {
            hr = Int(data[1])
            offset += 1
        }
        
        if (flags & 0x08) != 0 {
            offset += 2 // Skip Energy Expended
        }
        
        var rrIntervals: [Double] = []
        if rrPresent {
            while offset + 1 < data.count {
                let rrValue = Int(data[offset]) | (Int(data[offset+1]) << 8)
                let rrInSeconds = Double(rrValue) / 1024.0
                rrIntervals.append(rrInSeconds)
                offset += 2
            }
        }
        
        return (hr, rrIntervals)
    }
    
    private func parseCyclingPower(data: Data) -> (Int?, Int?, Double?) {
        guard data.count > 3 else { return (nil, nil, nil) }
        
        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        let powerLow = Int(data[2])
        let powerHigh = Int(data[3])
        let power = powerLow | (powerHigh << 8)
        
        var offset = 4
        var balance: Double? = nil
        
        let pedalPowerBalancePresent = (flags & 0x0001) != 0
        let accumulatedTorquePresent = (flags & 0x0004) != 0
        let wheelRevolutionDataPresent = (flags & 0x0010) != 0
        let cadencePresent = (flags & 0x0020) != 0
        
        if pedalPowerBalancePresent && data.count >= offset + 1 {
            balance = Double(data[offset]) / 2.0 // 1/2 % resolution
            offset += 1
        }
        
        if accumulatedTorquePresent { offset += 2 }
        if wheelRevolutionDataPresent { offset += 6 }
        
        var cadence: Int? = nil
        if cadencePresent && data.count >= offset + 4 {
            let crankRevolutions = Int(data[offset]) | (Int(data[offset+1]) << 8)
            let crankEventTime = Int(data[offset+2]) | (Int(data[offset+3]) << 8)
            
            if let lastRevs = lastCrankRevs, let lastTime = lastCrankTime {
                var revDiff = crankRevolutions - lastRevs
                if revDiff < 0 { revDiff += 65536 }
                
                var timeDiff = crankEventTime - lastTime
                if timeDiff < 0 { timeDiff += 65536 }
                
                if timeDiff > 0 && revDiff > 0 {
                    let rpm = (Double(revDiff) / (Double(timeDiff) / 1024.0)) * 60.0
                    cadence = Int(round(rpm))
                } else if timeDiff > 2048 { // More than 2 seconds since last event
                    cadence = 0 // Actually stopped
                }
            }
            
            lastCrankRevs = crankRevolutions
            lastCrankTime = crankEventTime
            
            offset += 4
        }
        
        return (power, cadence, balance)
    }
    
    private func parseIndoorBikeData(data: Data) -> (Int?, Int?) {
        guard data.count > 2 else { return (nil, nil) }
        
        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        var offset = 2
        
        var cadence: Int? = nil
        var power: Int? = nil
        
        // Instantaneous Speed present if Bit 0 is 0
        if (flags & 0x0001) == 0 { offset += 2 }
        
        // Average Speed present
        if (flags & 0x0002) != 0 { offset += 2 }
        
        // Instantaneous Cadence present
        if (flags & 0x0004) != 0 {
            if data.count >= offset + 2 {
                let cad = Int(data[offset]) | (Int(data[offset+1]) << 8)
                cadence = cad / 2
            }
            offset += 2
        }
        
        // Average Cadence present
        if (flags & 0x0008) != 0 { offset += 2 }
        
        // Total Distance present (UInt24)
        if (flags & 0x0010) != 0 { offset += 3 }
        
        // Resistance Level present
        if (flags & 0x0020) != 0 { offset += 2 }
        
        // Instantaneous Power present
        if (flags & 0x0040) != 0 {
            if data.count >= offset + 2 {
                let pwrLow = Int(data[data.startIndex + offset])
                let pwrHigh = Int(data[data.startIndex + offset + 1])
                var pwr = pwrLow | (pwrHigh << 8)
                if pwr > 32767 { pwr -= 65536 } // SInt16 conversion
                if pwr >= 0 { // Ignore negative power artifacts
                    power = pwr
                }
            }
            offset += 2
        }
        
        return (power, cadence)
    }
}

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    private var centralManager: CBCentralManager!
    
    @Published var isScanning = false
    @Published var peripherals: [DiscoveredPeripheral] = []

    
    private var cleanupTimer: AnyCancellable?
    
    private let serviceUUIDs = [
        CBUUID(string: "180D"), // Heart Rate
        CBUUID(string: "1818"), // Cycling Power
        CBUUID(string: "1826")  // Fitness Machine
    ]

    func startScanning() {
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

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        cleanupTimer?.cancel()
        cleanupTimer = nil
    }

    func connect(peripheral: DiscoveredPeripheral) {
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    func disconnect(peripheral: DiscoveredPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral.peripheral)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Ready to scan
        } else {
            isScanning = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
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

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) {
                discovered.isConnected = true
                discovered.discoverServices()
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if let discovered = self.peripherals.first(where: { $0.id == peripheral.identifier }) {
                let wasConnected = discovered.isConnected
                
                discovered.isConnected = false
                discovered.heartRate = nil
                discovered.cyclingPower = nil
                discovered.cadence = nil
                
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

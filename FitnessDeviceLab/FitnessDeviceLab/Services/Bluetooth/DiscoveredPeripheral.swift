import Foundation
import CoreBluetooth
import Combine
import Observation

public enum DeviceCapability: String, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case cyclingPower = "Power Meter"
    case fitnessMachine = "Smart Trainer"
    case cadence = "Cadence Sensor"
    
    public var id: String { rawValue }
}

public struct TimeSeriesDataPoint: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp = Date()
    public let value: Double
    
    public init(value: Double) {
        self.value = value
    }
}

@Observable @MainActor
public class DiscoveredPeripheral: NSObject, Identifiable, SensorPeripheral {
    public let id: UUID
    public let peripheral: CBPeripheral
    
    public var name: String
    public var rssi: NSNumber
    public var isConnected: Bool = false
    public var expectedDisconnect: Bool = false
    
    // Static Data
    public var manufacturerName: String?
    public var modelNumber: String?
    public var firmwareRevision: String?
    
    // Dynamic Data
    public var heartRate: Int?
    public var cyclingPower: Int?
    public var cadence: Int?
    public var batteryLevel: Int?
    
    // Internal state for diff-based cadence calculation
    public var lastCrankRevs: Int?
    public var lastCrankTime: Int?
    public var lastCSCRevs: Int?
    public var lastCSCTime: Int?
    
    public var powerBalance: Double? // 0.0 to 100.0% (Left)
    
    // Capabilities
    public var capabilities: Set<DeviceCapability> = []
    
    // Connectivity State
    public var lastSeen: Date = Date()
    
    // Debug Data
    public var rawDataHex: String?
    
    // Latest RR Intervals
    public var latestRRIntervals: [Double] = []
    
    // FTMS State
    public var controlPointCharacteristic: CBCharacteristic?
    public var isControlRequested = false
    public var isMachineStarted = false
    
    // FTMS Range Data
    public var minResistance: Double = 0
    public var maxResistance: Double = 100
    public var resistanceIncrement: Double = 1.0
    
    // FTMS Capabilities (from 0x2ACC)
    public var supportsResistanceControl = false
    public var supportsPowerControl = false
    public var supportsSimulationControl = false
    
    private var pendingPower: Int?
    private var pendingResistance: Double?
    
    public init(peripheral: CBPeripheral, rssi: NSNumber) {
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
    private static let cscServiceUUID = CBUUID(string: "1816") // Cycling Speed and Cadence
    private static let deviceInfoServiceUUID = CBUUID(string: "180A")
    private static let batteryServiceUUID = CBUUID(string: "180F")
    
    // Standard Characteristic UUIDs
    private static let heartRateMeasurementUUID = CBUUID(string: "2A37")
    private static let cyclingPowerMeasurementUUID = CBUUID(string: "2A63")
    private static let indoorBikeDataUUID = CBUUID(string: "2AD2")
    private static let cscMeasurementUUID = CBUUID(string: "2A5B")
    private static let fitnessMachineControlPointUUID = CBUUID(string: "2AD9")
    private static let fitnessMachineFeatureUUID = CBUUID(string: "2ACC")
    private static let fitnessMachineStatusUUID = CBUUID(string: "2ADA")
    private static let supportedResistanceLevelRangeUUID = CBUUID(string: "2AD6")
    
    private static let manufacturerNameUUID = CBUUID(string: "2A29")
    private static let modelNumberUUID = CBUUID(string: "2A24")
    private static let firmwareRevisionUUID = CBUUID(string: "2A26")
    private static let batteryLevelUUID = CBUUID(string: "2A19")
    
    public func discoverServices() {
        peripheral.discoverServices([
            Self.heartRateServiceUUID,
            Self.cyclingPowerServiceUUID,
            Self.fitnessMachineServiceUUID,
            Self.cscServiceUUID,
            Self.deviceInfoServiceUUID,
            Self.batteryServiceUUID
        ])
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == Self.heartRateServiceUUID { self.capabilities.insert(.heartRate) }
            if service.uuid == Self.cyclingPowerServiceUUID { self.capabilities.insert(.cyclingPower) }
            if service.uuid == Self.fitnessMachineServiceUUID { self.capabilities.insert(.fitnessMachine) }
            if service.uuid == Self.cscServiceUUID { self.capabilities.insert(.cadence) }
            
            switch service.uuid {
            case Self.heartRateServiceUUID:
                peripheral.discoverCharacteristics([Self.heartRateMeasurementUUID], for: service)
            case Self.cyclingPowerServiceUUID:
                peripheral.discoverCharacteristics([Self.cyclingPowerMeasurementUUID], for: service)
            case Self.fitnessMachineServiceUUID:
                peripheral.discoverCharacteristics([
                    Self.indoorBikeDataUUID,
                    Self.fitnessMachineControlPointUUID,
                    Self.fitnessMachineFeatureUUID,
                    Self.fitnessMachineStatusUUID,
                    Self.supportedResistanceLevelRangeUUID
                ], for: service)
            case Self.cscServiceUUID:
                peripheral.discoverCharacteristics([Self.cscMeasurementUUID], for: service)
            case Self.deviceInfoServiceUUID:
                peripheral.discoverCharacteristics([Self.manufacturerNameUUID, Self.modelNumberUUID, Self.firmwareRevisionUUID], for: service)
            case Self.batteryServiceUUID:
                peripheral.discoverCharacteristics([Self.batteryLevelUUID], for: service)
            default:
                break
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == Self.fitnessMachineControlPointUUID {
                self.controlPointCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        self.rawDataHex = data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        
        switch characteristic.uuid {
        case Self.fitnessMachineFeatureUUID:
            self.parseFTMSFeatures(data: data)
        case Self.supportedResistanceLevelRangeUUID:
            self.parseResistanceRange(data: data)
        case Self.heartRateMeasurementUUID:
            let result = SensorDataParser.parseHeartRate(data: data)
            self.heartRate = result.hr
            if !result.rrIntervals.isEmpty {
                self.latestRRIntervals = result.rrIntervals
            }
        case Self.cyclingPowerMeasurementUUID:
            let result = SensorDataParser.parseCyclingPower(data: data, lastCrankRevs: self.lastCrankRevs, lastCrankTime: self.lastCrankTime)
            if let power = result.power { self.cyclingPower = power }
            if let cadence = result.cadence { self.cadence = cadence }
            if let balance = result.balance { self.powerBalance = balance }
            self.lastCrankRevs = result.crankRevs
            self.lastCrankTime = result.crankTime
        case Self.cscMeasurementUUID:
            let result = SensorDataParser.parseCSC(data: data, lastCrankRevs: self.lastCSCRevs, lastCrankTime: self.lastCSCTime)
            if let cadence = result.cadence { self.cadence = cadence }
            self.lastCSCRevs = result.crankRevs
            self.lastCSCTime = result.crankTime
        case Self.indoorBikeDataUUID:
            let result = SensorDataParser.parseIndoorBikeData(data: data)
            if let power = result.power { self.cyclingPower = power }
            if let cadence = result.cadence { self.cadence = cadence }
        case Self.fitnessMachineControlPointUUID:
            self.handleControlPointResponse(data: data)
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
    
    private func parseFTMSFeatures(data: Data) {
        // FTMS Feature: 8 bytes (4 for Machine Features, 4 for Target Setting Features)
        guard data.count >= 8 else { return }
        
        // We are mostly interested in Target Setting Features (Bytes 4-7)
        let targetFeatures = UInt32(data[4]) | (UInt32(data[5]) << 8) | (UInt32(data[6]) << 16) | (UInt32(data[7]) << 24)
        
        self.supportsResistanceControl = (targetFeatures & 0x01) != 0
        self.supportsPowerControl = (targetFeatures & 0x02) != 0
        self.supportsSimulationControl = (targetFeatures & 0x08) != 0
        
        print("FTMS Features for \(name): Resistance=\(supportsResistanceControl), Power=\(supportsPowerControl), Sim=\(supportsSimulationControl)")
    }
    
    private func parseResistanceRange(data: Data) {
        guard data.count >= 6 else { return }
        
        let minRaw = Int16(bitPattern: UInt16(data[0]) | (UInt16(data[1]) << 8))
        let maxRaw = Int16(bitPattern: UInt16(data[2]) | (UInt16(data[3]) << 8))
        let incRaw = UInt16(data[4]) | (UInt16(data[5]) << 8)
        
        self.minResistance = Double(minRaw) * 0.1
        self.maxResistance = Double(maxRaw) * 0.1
        self.resistanceIncrement = Double(incRaw) * 0.1
        
        print("Resistance Range for \(name): \(minResistance) to \(maxResistance) step \(resistanceIncrement)")
    }
    
    private func handleControlPointResponse(data: Data) {
        guard data.count >= 3 else { return }
        let responseCode = data[0]
        let requestOpCode = data[1]
        let result = data[2]
        
        if responseCode == 0x80 { // Response Code
            switch requestOpCode {
            case 0x00: // Request Control
                if result == 0x01 { // Success
                    self.isControlRequested = true
                    print("Control acquired for \(name). Starting machine...")
                    sendStartMachine()
                } else if result == 0x04 { // Operation Failed / Already Controlled
                    print("Failed to acquire control for \(name): Error 4 (Already controlled or busy). Attempting Reset...")
                    sendResetMachine()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.requestControl()
                    }
                } else {
                    print("Failed to acquire control for \(name): \(result)")
                }
            case 0x07: // Start or Resume
                if result == 0x01 {
                    self.isMachineStarted = true
                    print("Machine started for \(name). Processing pending commands.")
                    processPendingCommands()
                } else {
                    print("Failed to start machine for \(name): \(result)")
                }
            default:
                if result != 0x01 {
                    print("FTMS Command \(requestOpCode) failed with result \(result)")
                }
            }
        }
    }
    
    private func sendStartMachine() {
        guard let cp = controlPointCharacteristic else { return }
        let startData = Data([0x07]) // Start or Resume OpCode
        peripheral.writeValue(startData, for: cp, type: .withResponse)
    }
    
    private func sendResetMachine() {
        guard let cp = controlPointCharacteristic else { return }
        let resetData = Data([0x01]) // Reset OpCode
        peripheral.writeValue(resetData, for: cp, type: .withResponse)
    }
    
    private func requestControl() {
        guard let cp = controlPointCharacteristic else { return }
        let requestControlData = Data([0x00])
        peripheral.writeValue(requestControlData, for: cp, type: .withResponse)
    }
    
    private func processPendingCommands() {
        if let pwr = pendingPower {
            setTargetPower(pwr)
            pendingPower = nil
        }
        if let res = pendingResistance {
            setResistanceLevel(res)
            pendingResistance = nil
        }
    }
    
    public func setTargetPower(_ watts: Int) {
        guard let cp = controlPointCharacteristic else { return }
        
        if !supportsPowerControl {
            print("Warning: \(name) does not support Power Target control.")
            // Even if not strictly reported, some trainers work anyway. 
            // We'll proceed but log the warning.
        }
        
        if !isControlRequested {
            pendingPower = watts
            requestControl()
            return
        }
        
        if !isMachineStarted {
            pendingPower = watts
            sendStartMachine()
            return
        }
        
        var data = Data([0x05]) // Set Target Power OpCode
        let power = UInt16(max(0, min(watts, 4000)))
        data.append(UInt8(power & 0xFF))
        data.append(UInt8((power >> 8) & 0xFF))
        
        peripheral.writeValue(data, for: cp, type: .withResponse)
    }
    
    public func setResistanceLevel(_ level: Double) {
        guard let cp = controlPointCharacteristic else { return }
        
        if !supportsResistanceControl {
            print("Warning: \(name) does not support Resistance control.")
        }
        
        if !isControlRequested {
            pendingResistance = level
            requestControl()
            return
        }
        
        if !isMachineStarted {
            pendingResistance = level
            sendStartMachine()
            return
        }
        
        var data = Data([0x04]) // Set Resistance Level OpCode
        
        let scaledLevel = minResistance + (maxResistance - minResistance) * (level / 100.0)
        let val = Int16(round(scaledLevel * 10.0))
        data.append(UInt8(UInt16(bitPattern: val) & 0xFF))
        data.append(UInt8((UInt16(bitPattern: val) >> 8) & 0xFF))
        
        peripheral.writeValue(data, for: cp, type: .withResponse)
    }
}

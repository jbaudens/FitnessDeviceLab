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
    
    // Handlers
    private let hrHandler = HeartRateHandler()
    private let powerHandler = PowerMeterHandler()
    private let ftmsHandler = FTMSHandler()
    
    // FTMS State required for protocol compliance
    public var controlPointCharacteristic: CBCharacteristic?
    
    // FTMS Capabilities (from 0x2ACC) exposed via handler
    public var supportsResistanceControl: Bool { ftmsHandler.supportsResistanceControl }
    public var supportsPowerControl: Bool { ftmsHandler.supportsPowerControl }
    public var supportsSimulationControl: Bool { ftmsHandler.supportsSimulationControl }
    
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
            ftmsHandler.parseFeatures(data: data, peripheral: self)
        case Self.supportedResistanceLevelRangeUUID:
            ftmsHandler.parseResistanceRange(data: data)
        case Self.heartRateMeasurementUUID:
            hrHandler.handleMeasurement(data: data, peripheral: self)
        case Self.cyclingPowerMeasurementUUID:
            powerHandler.handleCyclingPowerMeasurement(data: data, peripheral: self)
        case Self.cscMeasurementUUID:
            powerHandler.handleCSCMeasurement(data: data, peripheral: self)
        case Self.indoorBikeDataUUID:
            ftmsHandler.handleIndoorBikeData(data: data, peripheral: self)
        case Self.fitnessMachineControlPointUUID:
            ftmsHandler.handleControlPointResponse(data: data, peripheral: self)
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
    
    public func setTargetPower(_ watts: Int) {
        ftmsHandler.setTargetPower(watts, peripheral: self)
    }
    
    public func setResistanceLevel(_ level: Double) {
        ftmsHandler.setResistanceLevel(level, peripheral: self)
    }
}

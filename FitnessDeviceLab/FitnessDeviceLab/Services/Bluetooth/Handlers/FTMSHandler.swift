import Foundation
import CoreBluetooth

@MainActor
class FTMSHandler {
    // FTMS Range Data
    var minResistance: Double = 0
    var maxResistance: Double = 100
    var resistanceIncrement: Double = 1.0
    
    // FTMS Capabilities
    var supportsResistanceControl = false
    var supportsPowerControl = false
    var supportsSimulationControl = false
    
    // State
    var isControlRequested = false
    var isMachineStarted = false
    var pendingPower: Int?
    var pendingResistance: Double?
    
    func parseFeatures(data: Data, peripheral: DiscoveredPeripheral) {
        guard data.count >= 8 else { return }
        let targetFeatures = UInt32(data[4]) | (UInt32(data[5]) << 8) | (UInt32(data[6]) << 16) | (UInt32(data[7]) << 24)
        
        self.supportsResistanceControl = (targetFeatures & 0x01) != 0
        self.supportsPowerControl = (targetFeatures & 0x02) != 0
        self.supportsSimulationControl = (targetFeatures & 0x08) != 0
    }
    
    func parseResistanceRange(data: Data) {
        guard data.count >= 6 else { return }
        
        let minRaw = Int16(bitPattern: UInt16(data[0]) | (UInt16(data[1]) << 8))
        let maxRaw = Int16(bitPattern: UInt16(data[2]) | (UInt16(data[3]) << 8))
        let incRaw = UInt16(data[4]) | (UInt16(data[5]) << 8)
        
        self.minResistance = Double(minRaw) * 0.1
        self.maxResistance = Double(maxRaw) * 0.1
        self.resistanceIncrement = Double(incRaw) * 0.1
    }
    
    func handleIndoorBikeData(data: Data, peripheral: DiscoveredPeripheral) {
        let result = SensorDataParser.parseIndoorBikeData(data: data)
        if let power = result.power { peripheral.cyclingPower = power }
        if let cadence = result.cadence { peripheral.cadence = cadence }
    }
    
    func handleControlPointResponse(data: Data, peripheral: DiscoveredPeripheral) {
        guard data.count >= 3 else { return }
        let responseCode = data[0]
        let requestOpCode = data[1]
        let result = data[2]
        
        if responseCode == 0x80 { // Response Code
            switch requestOpCode {
            case 0x00: // Request Control
                if result == 0x01 { // Success
                    self.isControlRequested = true
                    sendStartMachine(peripheral: peripheral)
                } else if result == 0x04 { // Operation Failed / Already Controlled
                    sendResetMachine(peripheral: peripheral)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.requestControl(peripheral: peripheral)
                    }
                }
            case 0x07: // Start or Resume
                if result == 0x01 {
                    self.isMachineStarted = true
                    processPendingCommands(peripheral: peripheral)
                }
            default:
                break
            }
        }
    }
    
    private func sendStartMachine(peripheral: DiscoveredPeripheral) {
        guard let cp = peripheral.controlPointCharacteristic else { return }
        let startData = Data([0x07])
        peripheral.peripheral.writeValue(startData, for: cp, type: .withResponse)
    }
    
    private func sendResetMachine(peripheral: DiscoveredPeripheral) {
        guard let cp = peripheral.controlPointCharacteristic else { return }
        let resetData = Data([0x01])
        peripheral.peripheral.writeValue(resetData, for: cp, type: .withResponse)
    }
    
    private func requestControl(peripheral: DiscoveredPeripheral) {
        guard let cp = peripheral.controlPointCharacteristic else { return }
        let requestControlData = Data([0x00])
        peripheral.peripheral.writeValue(requestControlData, for: cp, type: .withResponse)
    }
    
    private func processPendingCommands(peripheral: DiscoveredPeripheral) {
        if let pwr = pendingPower {
            setTargetPower(pwr, peripheral: peripheral)
            pendingPower = nil
        }
        if let res = pendingResistance {
            setResistanceLevel(res, peripheral: peripheral)
            pendingResistance = nil
        }
    }
    
    func setTargetPower(_ watts: Int, peripheral: DiscoveredPeripheral) {
        guard let cp = peripheral.controlPointCharacteristic else { return }
        
        if !isControlRequested {
            pendingPower = watts
            requestControl(peripheral: peripheral)
            return
        }
        
        if !isMachineStarted {
            pendingPower = watts
            sendStartMachine(peripheral: peripheral)
            return
        }
        
        var data = Data([0x05]) // Set Target Power OpCode
        let power = UInt16(max(0, min(watts, 4000)))
        data.append(UInt8(power & 0xFF))
        data.append(UInt8((power >> 8) & 0xFF))
        
        peripheral.peripheral.writeValue(data, for: cp, type: .withResponse)
    }
    
    func setResistanceLevel(_ level: Double, peripheral: DiscoveredPeripheral) {
        guard let cp = peripheral.controlPointCharacteristic else { return }
        
        if !isControlRequested {
            pendingResistance = level
            requestControl(peripheral: peripheral)
            return
        }
        
        if !isMachineStarted {
            pendingResistance = level
            sendStartMachine(peripheral: peripheral)
            return
        }
        
        var data = Data([0x04]) // Set Resistance Level OpCode
        let scaledLevel = minResistance + (maxResistance - minResistance) * (level / 100.0)
        let val = Int16(round(scaledLevel * 10.0))
        data.append(UInt8(UInt16(bitPattern: val) & 0xFF))
        data.append(UInt8((UInt16(bitPattern: val) >> 8) & 0xFF))
        
        peripheral.peripheral.writeValue(data, for: cp, type: .withResponse)
    }
}

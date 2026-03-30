import Foundation

@MainActor
class PowerMeterHandler {
    private var lastCrankRevs: Int?
    private var lastCrankTime: Int?
    private var lastCSCRevs: Int?
    private var lastCSCTime: Int?
    
    func handleCyclingPowerMeasurement(data: Data, peripheral: DiscoveredPeripheral) {
        let result = SensorDataParser.parseCyclingPower(data: data, lastCrankRevs: lastCrankRevs, lastCrankTime: lastCrankTime)
        if let power = result.power { peripheral.cyclingPower = power }
        if let cadence = result.cadence { peripheral.cadence = cadence }
        if let balance = result.balance { peripheral.powerBalance = balance }
        self.lastCrankRevs = result.crankRevs
        self.lastCrankTime = result.crankTime
    }
    
    func handleCSCMeasurement(data: Data, peripheral: DiscoveredPeripheral) {
        let result = SensorDataParser.parseCSC(data: data, lastCrankRevs: lastCSCRevs, lastCrankTime: lastCSCTime)
        if let cadence = result.cadence { peripheral.cadence = cadence }
        self.lastCSCRevs = result.crankRevs
        self.lastCSCTime = result.crankTime
    }
}

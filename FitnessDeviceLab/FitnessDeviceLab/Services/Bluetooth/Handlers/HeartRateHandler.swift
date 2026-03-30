import Foundation

@MainActor
class HeartRateHandler {
    func handleMeasurement(data: Data, peripheral: DiscoveredPeripheral) {
        let result = SensorDataParser.parseHeartRate(data: data)
        peripheral.heartRate = result.hr
        if !result.rrIntervals.isEmpty {
            peripheral.latestRRIntervals = result.rrIntervals
        }
    }
}

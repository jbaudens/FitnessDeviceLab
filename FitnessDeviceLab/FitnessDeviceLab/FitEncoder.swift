import Foundation
import FITSwiftSDK
import CoreBluetooth

/// A FIT file encoder using the official Garmin FIT Swift SDK.
class FitEncoder {
    
    init() {}
    
    private func mapManufacturer(_ name: String?) -> Manufacturer {
        guard let name = name?.lowercased() else { return .development }
        
        if name.contains("garmin") { return .garmin }
        if name.contains("wahoo") { return .wahooFitness }
        if name.contains("tacx") { return .tacx }
        if name.contains("stages") { return .stagesCycling }
        if name.contains("zwift") { return .zwift }
        if name.contains("magene") { return .magene }
        if name.contains("bryton") { return .bryton }
        if name.contains("sram") { return .sram }
        if name.contains("shimano") { return .shimano }
        if name.contains("hammerhead") { return .hammerhead }
        if name.contains("specialized") { return .specialized }
        
        return .development // Fallback
    }
    
    func encode(trackpoints: [Trackpoint], laps: [Lap], hrDevice: DiscoveredPeripheral?, powerDevice: DiscoveredPeripheral?, userFTP: Double, userWeight: Double) -> Data? {
        guard !trackpoints.isEmpty else { return nil }
        
        let encoder = Encoder()
        
        // 1. File ID Message (Required first message)
        let fileId = FileIdMesg()
        try? fileId.setType(.activity)
        try? fileId.setManufacturer(mapManufacturer(powerDevice?.manufacturerName ?? hrDevice?.manufacturerName))
        try? fileId.setProduct(1)
        try? fileId.setSerialNumber(UInt32(12345))
        if let firstTime = trackpoints.first?.time {
            try? fileId.setTimeCreated(DateTime(date: firstTime))
        } else {
            try? fileId.setTimeCreated(DateTime(date: Date()))
        }
        encoder.write(mesg: fileId)
        
        // 2. User Profile Message
        let user = UserProfileMesg()
        try? user.setWeight(Float64(userWeight))
        encoder.write(mesg: user)
        
        // 3. Device Info Messages (for sensors)
        if let hr = hrDevice {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: trackpoints.first!.time))
            try? info.setDeviceIndex(UInt8(1))
            try? info.setDeviceType(120) // Heart Rate
            try? info.setManufacturer(mapManufacturer(hr.manufacturerName))
            if let model = hr.modelNumber { try? info.setProductName(model) }
            if let serial = UInt32(hr.peripheral.identifier.uuidString.prefix(8), radix: 16) {
                try? info.setSerialNumber(serial)
            }
            encoder.write(mesg: info)
        }
        
        if let pwr = powerDevice {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: trackpoints.first!.time))
            try? info.setDeviceIndex(UInt8(2))
            try? info.setDeviceType(11) // Power
            try? info.setManufacturer(mapManufacturer(pwr.manufacturerName))
            if let model = pwr.modelNumber { try? info.setProductName(model) }
            if let serial = UInt32(pwr.peripheral.identifier.uuidString.prefix(8), radix: 16) {
                try? info.setSerialNumber(serial)
            }
            encoder.write(mesg: info)
        }
        
        // 4. Activity Message
        let activity = ActivityMesg()
        try? activity.setNumSessions(1)
        try? activity.setType(.manual)
        try? activity.setEvent(.activity)
        try? activity.setEventType(.stop)
        encoder.write(mesg: activity)
        
        // 5. Record Messages
        for pt in trackpoints {
            let record = RecordMesg()
            try? record.setTimestamp(DateTime(date: pt.time))
            
            if let hr = pt.hr {
                try? record.setHeartRate(UInt8(hr))
            }
            
            if let power = pt.power {
                try? record.setPower(UInt16(power))
            }
            
            if let cadence = pt.cadence {
                try? record.setCadence(UInt8(cadence))
            }
            
            if let alt = pt.altitude {
                try? record.setAltitude(Float64(alt))
            }
            
            encoder.write(mesg: record)
        }
        
        // 6. Lap Messages
        for lap in laps {
            let lapMesg = LapMesg()
            try? lapMesg.setStartTime(DateTime(date: lap.startTime))
            let endTime = lap.endTime ?? Date()
            try? lapMesg.setTimestamp(DateTime(date: endTime))
            try? lapMesg.setTotalElapsedTime(Float64(endTime.timeIntervalSince(lap.startTime)))
            try? lapMesg.setTotalTimerTime(Float64(endTime.timeIntervalSince(lap.startTime)))
            
            // Calculate averages for the lap from trackpoints
            let lapPoints = trackpoints.filter { $0.time >= lap.startTime && $0.time <= endTime }
            if !lapPoints.isEmpty {
                let avgPower = lapPoints.compactMap { $0.power }.reduce(0, +) / lapPoints.count
                try? lapMesg.setAvgPower(UInt16(avgPower))
                
                let avgHR = lapPoints.compactMap { $0.hr }.reduce(0, +) / lapPoints.count
                try? lapMesg.setAvgHeartRate(UInt8(avgHR))
                
                let avgCadence = lapPoints.compactMap { $0.cadence }.reduce(0, +) / lapPoints.count
                try? lapMesg.setAvgCadence(UInt8(avgCadence))
            }
            
            encoder.write(mesg: lapMesg)
        }
        
        return encoder.close()
    }
}

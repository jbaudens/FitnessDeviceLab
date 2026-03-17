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
        if name.contains("whoop") { return .whoop }
        
        return .development // Fallback
    }
    
    func encode(trackpoints: [Trackpoint], laps: [Lap], hrSource: (any HeartRateProviding)?, powerSource: (any PowerProviding)?, userFTP: Double, userWeight: Double) -> Data? {
        guard !trackpoints.isEmpty else { return nil }
        
        let encoder = Encoder()
        let startTime = trackpoints.first!.time
        let endTime = trackpoints.last!.time
        let totalWeight = userWeight + 6.8 // User + UCI limit bike
        
        // 1. File ID Message (Required first message)
        let fileId = FileIdMesg()
        try? fileId.setType(.activity)
        try? fileId.setManufacturer(.development)
        try? fileId.setProduct(1)
        try? fileId.setSerialNumber(UInt32(12345))
        try? fileId.setTimeCreated(DateTime(date: startTime))
        encoder.write(mesg: fileId)
        
        // 2. User Profile
        let user = UserProfileMesg()
        try? user.setWeight(Float64(userWeight))
        encoder.write(mesg: user)
        
        // 3. Sensor Info
        if let hr = hrSource as? HeartRateSensor {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: startTime))
            try? info.setDeviceIndex(UInt8(1))
            try? info.setDeviceType(120)
            try? info.setManufacturer(mapManufacturer(hr.manufacturerName))
            if let model = hr.modelNumber { try? info.setProductName(model) }
            encoder.write(mesg: info)
        }
        
        if let pwr = powerSource as? PowerSensor {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: startTime))
            try? info.setDeviceIndex(UInt8(2))
            try? info.setDeviceType(11)
            try? info.setManufacturer(mapManufacturer(pwr.manufacturerName))
            if let model = pwr.modelNumber { try? info.setProductName(model) }
            encoder.write(mesg: info)
        } else if let pwr = powerSource as? ControllableTrainer {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: startTime))
            try? info.setDeviceIndex(UInt8(2))
            try? info.setDeviceType(11)
            try? info.setManufacturer(mapManufacturer(pwr.manufacturerName))
            if let model = pwr.modelNumber { try? info.setProductName(model) }
            encoder.write(mesg: info)
        }
        
        // 4. Timer Events (Start)
        let startEvent = EventMesg()
        try? startEvent.setTimestamp(DateTime(date: startTime))
        try? startEvent.setEvent(.timer)
        try? startEvent.setEventType(.start)
        encoder.write(mesg: startEvent)
        
        // 5. Trackpoints
        var totalDistance: Double = 0
        var speeds: [Double] = []
        
        for i in 0..<trackpoints.count {
            let pt = trackpoints[i]
            let record = RecordMesg()
            try? record.setTimestamp(DateTime(date: pt.time))
            
            if let hr = pt.hr { try? record.setHeartRate(UInt8(hr)) }
            if let pwr = pt.power { try? record.setPower(UInt16(pwr)) }
            if let cad = pt.cadence { try? record.setCadence(UInt8(cad)) }
            if let alt = pt.altitude { try? record.setAltitude(Float64(alt)) }
            
            // Power Balance (L/R)
            if let balance = pt.powerBalance {
                // SB20 balance is % Left. FIT standard for cycling is % Right with Bit 7 (0x80) set to 1.
                let rightPercent = 100.0 - balance
                let fitBalance = UInt8(max(0, min(round(rightPercent), 100))) | 0x80
                try? record.setLeftRightBalance(LeftRightBalance(fitBalance))
            }
            
            // Speed and Distance Estimation
            let power = Double(pt.power ?? 0)
            let speed = PhysicsUtilities.estimateSpeed(power: power, totalWeight: totalWeight)
            speeds.append(speed)
            
            if i > 0 {
                let dt = pt.time.timeIntervalSince(trackpoints[i-1].time)
                if dt > 0 && dt < 10 { // Ignore gaps > 10s for distance
                    totalDistance += speed * dt
                }
            }
            
            try? record.setSpeed(Float64(speed))
            try? record.setDistance(Float64(totalDistance))
            encoder.write(mesg: record)
        }
        
        // 6. Timer Events (Stop)
        let stopEvent = EventMesg()
        try? stopEvent.setTimestamp(DateTime(date: endTime))
        try? stopEvent.setEvent(.timer)
        try? stopEvent.setEventType(.stopAll)
        encoder.write(mesg: stopEvent)
        
        // 7. Laps
        for lap in laps {
            let lapMesg = LapMesg()
            let lapEnd = lap.endTime ?? endTime
            try? lapMesg.setStartTime(DateTime(date: lap.startTime))
            try? lapMesg.setTimestamp(DateTime(date: lapEnd))
            try? lapMesg.setTotalElapsedTime(Float64(lapEnd.timeIntervalSince(lap.startTime)))
            try? lapMesg.setTotalTimerTime(Float64(lap.duration))
            
            let lapPoints = trackpoints.filter { $0.time >= lap.startTime && $0.time <= lapEnd }
            if !lapPoints.isEmpty {
                let pwrSamples = lapPoints.compactMap { $0.power }
                if !pwrSamples.isEmpty {
                    try? lapMesg.setAvgPower(UInt16(pwrSamples.reduce(0, +) / pwrSamples.count))
                    try? lapMesg.setMaxPower(UInt16(pwrSamples.max() ?? 0))
                }
                
                let lrSamples = lapPoints.compactMap { $0.powerBalance }
                if !lrSamples.isEmpty {
                    let avgLeft = lrSamples.reduce(0, +) / Double(lrSamples.count)
                    let avgRight = 100.0 - avgLeft
                    // LeftRightBalance100 uses scale 100 and bit 15 (0x8000) for Right
                    let fitAvgLRValue = UInt16(max(0, min(round(avgRight * 100.0), 10000))) | 0x8000
                    try? lapMesg.setLeftRightBalance(LeftRightBalance100(fitAvgLRValue))
                }
                
                let hrSamples = lapPoints.compactMap { $0.hr }
                if !hrSamples.isEmpty {
                    try? lapMesg.setAvgHeartRate(UInt8(hrSamples.reduce(0, +) / hrSamples.count))
                    try? lapMesg.setMaxHeartRate(UInt8(hrSamples.max() ?? 0))
                }
                
                let lapSpeeds = lapPoints.map { PhysicsUtilities.estimateSpeed(power: Double($0.power ?? 0), totalWeight: totalWeight) }
                if !lapSpeeds.isEmpty {
                    try? lapMesg.setAvgSpeed(Float64(lapSpeeds.reduce(0, +) / Double(lapSpeeds.count)))
                    try? lapMesg.setMaxSpeed(Float64(lapSpeeds.max() ?? 0))
                }
            }
            encoder.write(mesg: lapMesg)
        }
        
        // 8. Session (Main Activity container)
        let session = SessionMesg()
        try? session.setTimestamp(DateTime(date: endTime))
        try? session.setStartTime(DateTime(date: startTime))
        try? session.setTotalElapsedTime(Float64(endTime.timeIntervalSince(startTime)))
        try? session.setTotalTimerTime(Float64(trackpoints.count)) // Crude but reliable moving time
        try? session.setTotalDistance(Float64(totalDistance))
        try? session.setSport(Sport.cycling)
        try? session.setSubSport(SubSport.indoorCycling)
        try? session.setFirstLapIndex(0)
        try? session.setNumLaps(UInt16(laps.count))
        
        let totalSpeeds = trackpoints.map { PhysicsUtilities.estimateSpeed(power: Double($0.power ?? 0), totalWeight: totalWeight) }
        if !totalSpeeds.isEmpty {
            try? session.setAvgSpeed(Float64(totalSpeeds.reduce(0, +) / Double(totalSpeeds.count)))
            try? session.setMaxSpeed(Float64(totalSpeeds.max() ?? 0))
        }
        
        let pwrSamples = trackpoints.compactMap { $0.power }
        if !pwrSamples.isEmpty {
            try? session.setAvgPower(UInt16(pwrSamples.reduce(0, +) / pwrSamples.count))
            try? session.setMaxPower(UInt16(pwrSamples.max() ?? 0))
        }
        
        let lrSamples = trackpoints.compactMap { $0.powerBalance }
        if !lrSamples.isEmpty {
            let avgLeft = lrSamples.reduce(0, +) / Double(lrSamples.count)
            let avgRight = 100.0 - avgLeft
            // LeftRightBalance100 uses scale 100 and bit 15 (0x8000) for Right
            let fitAvgLRValue = UInt16(max(0, min(round(avgRight * 100.0), 10000))) | 0x8000
            try? session.setLeftRightBalance(LeftRightBalance100(fitAvgLRValue))
        }
        
        encoder.write(mesg: session)
        
        // 9. Activity (Footer)
        let activity = ActivityMesg()
        try? activity.setTimestamp(DateTime(date: endTime))
        try? activity.setNumSessions(1)
        try? activity.setType(.manual)
        try? activity.setEvent(.activity)
        try? activity.setEventType(.stop)
        encoder.write(mesg: activity)
        
        return encoder.close()
    }
}

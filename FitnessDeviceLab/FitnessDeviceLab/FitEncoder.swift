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
    
    /// Estimated speed in m/s based on Power (W) and Weight (kg)
    /// Simple physics model assuming flat road, no wind, and typical rolling resistance/drag.
    nonisolated public static func estimateSpeed(power: Double, totalWeight: Double) -> Double {
        guard power > 0 else { return 0 }
        
        // Constants for a typical road bike on flats
        let frontalArea = 0.5 // m^2
        let dragCoefficient = 0.63
        let airDensity = 1.225 // kg/m^3
        let rollingResistanceCoeff = 0.005
        let gravity = 9.81
        
        // P = (Rolling Resistance + Drag) * Speed
        // P = (Crr * m * g + 0.5 * Cd * A * rho * v^2) * v
        // This is a cubic equation: v^3 * (0.5*Cd*A*rho) + v * (Crr*m*g) - P = 0
        
        let a = 0.5 * dragCoefficient * frontalArea * airDensity
        let b = rollingResistanceCoeff * totalWeight * gravity
        
        // Simple iterative solver for v (Newton's method or binary search)
        var v = 5.0 // start guess 18km/h
        for _ in 0..<5 {
            let f = a * pow(v, 3) + b * v - power
            let df = 3 * a * pow(v, 2) + b
            v = v - f / df
        }
        
        return max(0, v)
    }
    
    func encode(trackpoints: [Trackpoint], laps: [Lap], hrDevice: DiscoveredPeripheral?, powerDevice: DiscoveredPeripheral?, userFTP: Double, userWeight: Double) -> Data? {
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
        if let hr = hrDevice {
            let info = DeviceInfoMesg()
            try? info.setTimestamp(DateTime(date: startTime))
            try? info.setDeviceIndex(UInt8(1))
            try? info.setDeviceType(120)
            try? info.setManufacturer(mapManufacturer(hr.manufacturerName))
            if let model = hr.modelNumber { try? info.setProductName(model) }
            encoder.write(mesg: info)
        }
        
        if let pwr = powerDevice {
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
            
            // Speed and Distance Estimation
            let power = Double(pt.power ?? 0)
            let speed = Self.estimateSpeed(power: power, totalWeight: totalWeight)
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
                
                let hrSamples = lapPoints.compactMap { $0.hr }
                if !hrSamples.isEmpty {
                    try? lapMesg.setAvgHeartRate(UInt8(hrSamples.reduce(0, +) / hrSamples.count))
                    try? lapMesg.setMaxHeartRate(UInt8(hrSamples.max() ?? 0))
                }
                
                let lapSpeeds = lapPoints.map { Self.estimateSpeed(power: Double($0.power ?? 0), totalWeight: totalWeight) }
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
        
        let totalSpeeds = trackpoints.map { Self.estimateSpeed(power: Double($0.power ?? 0), totalWeight: totalWeight) }
        if !totalSpeeds.isEmpty {
            try? session.setAvgSpeed(Float64(totalSpeeds.reduce(0, +) / Double(totalSpeeds.count)))
            try? session.setMaxSpeed(Float64(totalSpeeds.max() ?? 0))
        }
        
        let pwrSamples = trackpoints.compactMap { $0.power }
        if !pwrSamples.isEmpty {
            try? session.setAvgPower(UInt16(pwrSamples.reduce(0, +) / pwrSamples.count))
            try? session.setMaxPower(UInt16(pwrSamples.max() ?? 0))
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

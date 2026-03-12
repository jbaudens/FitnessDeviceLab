import Foundation
import FITSwiftSDK

/// A FIT file encoder using the official Garmin FIT Swift SDK.
public class FitEncoder {
    
    public init() {}
    
    public func encode(trackpoints: [Trackpoint], laps: [Lap]) -> Data? {
        guard !trackpoints.isEmpty else { return nil }
        
        let encoder = Encoder()
        
        // 1. File ID Message (Required first message)
        let fileId = FileIdMesg()
        try? fileId.setType(.activity)
        try? fileId.setManufacturer(Manufacturer.garmin) // Generic
        try? fileId.setProduct(1)
        try? fileId.setSerialNumber(UInt32(12345))
        if let firstTime = trackpoints.first?.time {
            try? fileId.setTimeCreated(DateTime(date: firstTime))
        } else {
            try? fileId.setTimeCreated(DateTime(date: Date()))
        }
        encoder.write(mesg: fileId)
        
        // 2. Activity Message
        let activity = ActivityMesg()
        try? activity.setNumSessions(1)
        try? activity.setType(.manual)
        try? activity.setEvent(.activity)
        try? activity.setEventType(.stop)
        encoder.write(mesg: activity)
        
        // 3. Record Messages
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
        
        // 4. Lap Messages
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

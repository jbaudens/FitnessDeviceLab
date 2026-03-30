import Foundation

nonisolated public struct SensorDataParser {
    nonisolated public static func parseHeartRate(data: Data) -> (hr: Int?, rrIntervals: [Double]) {
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
                let rrInSeconds = Double(rrValue) / Constants.BLE.bleTimeResolution
                rrIntervals.append(rrInSeconds)
                offset += 2
            }
        }
        
        return (hr, rrIntervals)
    }
    
    nonisolated public static func parseCyclingPower(data: Data, lastCrankRevs: Int?, lastCrankTime: Int?) -> (power: Int?, cadence: Int?, balance: Double?, crankRevs: Int?, crankTime: Int?) {
        guard data.count > 3 else { return (nil, nil, nil, lastCrankRevs, lastCrankTime) }
        
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
        
        if accumulatedTorquePresent { offset += 4 }
        if wheelRevolutionDataPresent { offset += 6 }
        
        var cadence: Int? = nil
        var currentCrankRevs = lastCrankRevs
        var currentCrankTime = lastCrankTime
        
        if cadencePresent && data.count >= offset + 4 {
            let crankRevolutions = Int(data[offset]) | (Int(data[offset+1]) << 8)
            let crankEventTime = Int(data[offset+2]) | (Int(data[offset+3]) << 8)
            
            if let lastRevs = lastCrankRevs, let lastTime = lastCrankTime {
                var revDiff = crankRevolutions - lastRevs
                if revDiff < 0 { revDiff += 65536 }
                
                var timeDiff = crankEventTime - lastTime
                if timeDiff < 0 { timeDiff += 65536 }
                
                if timeDiff > 0 && revDiff > 0 {
                    let rpm = (Double(revDiff) / (Double(timeDiff) / Constants.BLE.bleTimeResolution)) * 60.0
                    cadence = Int(round(rpm))
                } else if timeDiff > 2048 { // More than 2 seconds since last event
                    cadence = 0 // Actually stopped
                }
            }
            
            currentCrankRevs = crankRevolutions
            currentCrankTime = crankEventTime
        }
        
        return (power, cadence, balance, currentCrankRevs, currentCrankTime)
    }
    
    nonisolated public static func parseIndoorBikeData(data: Data) -> (power: Int?, cadence: Int?) {
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
                let pwrLow = Int(data[offset])
                let pwrHigh = Int(data[offset + 1])
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
    
    nonisolated public static func parseCSC(data: Data, lastCrankRevs: Int?, lastCrankTime: Int?) -> (cadence: Int?, crankRevs: Int?, crankTime: Int?) {
        guard data.count >= 1 else { return (nil, lastCrankRevs, lastCrankTime) }
        
        let flags = data[0]
        let wheelRevPresent = (flags & 0x01) != 0
        let crankRevPresent = (flags & 0x02) != 0
        
        var offset = 1
        if wheelRevPresent {
            offset += 6 // Skip wheel data (4 bytes revs, 2 bytes time)
        }
        
        var cadence: Int? = nil
        var currentCrankRevs = lastCrankRevs
        var currentCrankTime = lastCrankTime
        
        if crankRevPresent && data.count >= offset + 4 {
            let crankRevolutions = Int(data[offset]) | (Int(data[offset+1]) << 8)
            let crankEventTime = Int(data[offset+2]) | (Int(data[offset+3]) << 8)
            
            if let lastRevs = lastCrankRevs, let lastTime = lastCrankTime {
                var revDiff = crankRevolutions - lastRevs
                if revDiff < 0 { revDiff += 65536 }
                
                var timeDiff = crankEventTime - lastTime
                if timeDiff < 0 { timeDiff += 65536 }
                
                if timeDiff > 0 && revDiff > 0 {
                    let rpm = (Double(revDiff) / (Double(timeDiff) / Constants.BLE.bleTimeResolution)) * 60.0
                    cadence = Int(round(rpm))
                } else if timeDiff > 2048 {
                    cadence = 0
                }
            }
            
            currentCrankRevs = crankRevolutions
            currentCrankTime = crankEventTime
        }
        
        return (cadence, currentCrankRevs, currentCrankTime)
    }
}

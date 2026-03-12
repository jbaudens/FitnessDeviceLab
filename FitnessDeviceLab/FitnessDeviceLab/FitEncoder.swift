import Foundation

/// A lightweight FIT file encoder for activity recording.
/// Reference: FIT SDK (Flexible and Interoperable Data Transfer)
public class FitEncoder {
    private var data = Data()
    private var crc: UInt16 = 0
    
    // FIT Epoch: Dec 31, 1989, 00:00:00 UTC
    private static let fitEpoch: Date = {
        var components = DateComponents()
        components.year = 1989
        components.month = 12
        components.day = 31
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar.current.date(from: components)!
    }()
    
    public static func toFitTimestamp(_ date: Date) -> UInt32 {
        return UInt32(max(0, date.timeIntervalSince(fitEpoch)))
    }
    
    public init() {}
    
    private func updateCRC(_ byte: UInt8) {
        let table: [UInt16] = [
            0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
            0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400
        ]
        
        var tmp: UInt16
        
        // Lower 4 bits
        tmp = table[Int(crc & 0xF)]
        crc = (crc >> 4) ^ tmp ^ table[Int(byte & 0xF)]
        
        // Upper 4 bits
        tmp = table[Int(crc & 0xF)]
        crc = (crc >> 4) ^ tmp ^ table[Int((byte >> 4) & 0xF)]
    }
    
    private func writeByte(_ byte: UInt8) {
        data.append(byte)
        updateCRC(byte)
    }
    
    private func writeBytes(_ bytes: [UInt8]) {
        for b in bytes { writeByte(b) }
    }
    
    private func writeUInt16(_ val: UInt16) {
        writeBytes(withUnsafeBytes(of: val.littleEndian) { Array($0) })
    }
    
    private func writeUInt32(_ val: UInt32) {
        writeBytes(withUnsafeBytes(of: val.littleEndian) { Array($0) })
    }
    
    private func writeInt32(_ val: Int32) {
        writeBytes(withUnsafeBytes(of: val.littleEndian) { Array($0) })
    }
    
    private func writeHeader(dataSize: UInt32) {
        var header = Data()
        header.append(14) // Header Size
        header.append(0x10) // Protocol Version (1.0)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2100).littleEndian) { Data($0) }) // Profile Version
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        header.append(contentsOf: ".FIT".data(using: .utf8)!)
        
        // Compute Header CRC
        var hCrc: UInt16 = 0
        func updateHCrc(_ byte: UInt8) {
            let table: [UInt16] = [
                0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
                0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400
            ]
            var tmp = table[Int(hCrc & 0xF)]
            hCrc = (hCrc >> 4) ^ tmp ^ table[Int(byte & 0xF)]
            tmp = table[Int(hCrc & 0xF)]
            hCrc = (hCrc >> 4) ^ tmp ^ table[Int((byte >> 4) & 0xF)]
        }
        for b in header { updateHCrc(b) }
        header.append(contentsOf: withUnsafeBytes(of: hCrc.littleEndian) { Data($0) })
        
        data.insert(contentsOf: header, at: 0)
    }
    
    public func encode(trackpoints: [Trackpoint], laps: [Lap]) -> Data {
        data = Data()
        crc = 0
        
        // 1. File ID Message (Global ID 0)
        // Definition
        writeBytes([0x40, 0x00, 0x00, 0x00, 0x00, 0x06]) // Header, Reserved, Little Endian, Global ID 0, Fields 6
        writeBytes([0, 1, 0x00]) // type (enum, 1 byte)
        writeBytes([1, 2, 0x84]) // manufacturer (uint16)
        writeBytes([2, 2, 0x84]) // product (uint16)
        writeBytes([3, 4, 0x8C]) // serial_number (uint32)
        writeBytes([4, 4, 0x8C]) // time_created (uint32)
        writeBytes([5, 2, 0x84]) // number (uint16)
        
        // Data (Local ID 0)
        let startTime = Self.toFitTimestamp(trackpoints.first?.time ?? Date())
        writeByte(0x00)
        writeByte(4) // Activity
        writeUInt16(1) // Garmin (example)
        writeUInt16(1) // Example product
        writeUInt32(12345) // Serial
        writeUInt32(startTime)
        writeUInt16(0)
        
        // 2. Record Definition (Global ID 20)
        // Fields: timestamp(253), position_lat(0), position_long(1), altitude(2), heart_rate(3), cadence(4), power(7)
        writeBytes([0x41, 0x00, 0x00, 20, 0x00, 0x07]) // Local ID 1, Global ID 20, 7 fields
        writeBytes([253, 4, 0x8C]) // timestamp (uint32)
        writeBytes([0, 4, 0x85])   // position_lat (sint32)
        writeBytes([1, 4, 0x85])   // position_long (sint32)
        writeBytes([2, 2, 0x84])   // altitude (uint16)
        writeBytes([3, 1, 0x02])   // heart_rate (uint8)
        writeBytes([4, 1, 0x02])   // cadence (uint8)
        writeBytes([7, 2, 0x84])   // power (uint16)
        
        // 3. Record Data Messages
        for pt in trackpoints {
            writeByte(0x01) // Local ID 1
            writeUInt32(Self.toFitTimestamp(pt.time))
            writeInt32(0) // Lat (not recorded)
            writeInt32(0) // Lon (not recorded)
            
            // Altitude (uint16, 1/5m + 500 offset) -> (alt + 500) * 5
            let altVal = pt.altitude != nil ? UInt16((pt.altitude! + 500.0) * 5.0) : 0xFFFF
            writeUInt16(altVal)
            
            writeByte(UInt8(pt.hr ?? 0xFF))
            writeByte(UInt8(pt.cadence ?? 0xFF))
            writeUInt16(UInt16(pt.power ?? 0xFFFF))
        }
        
        // 4. Lap Definition (Global ID 19)
        // Fields: timestamp(253), start_time(2), total_elapsed_time(7)
        writeBytes([0x42, 0x00, 0x00, 19, 0x00, 0x03]) // Local ID 2
        writeBytes([253, 4, 0x8C])
        writeBytes([2, 4, 0x8C])
        writeBytes([7, 4, 0x8C]) // total_elapsed_time (ms * 1000)
        
        for lap in laps {
            writeByte(0x02) // Local ID 2
            writeUInt32(Self.toFitTimestamp(lap.endTime ?? Date()))
            writeUInt32(Self.toFitTimestamp(lap.startTime))
            writeUInt32(UInt32((lap.endTime ?? Date()).timeIntervalSince(lap.startTime) * 1000))
        }
        
        // Finalize
        let dataSize = UInt32(data.count)
        let finalCrc = crc
        writeUInt16(finalCrc) // File CRC
        
        writeHeader(dataSize: dataSize)
        
        return data
    }
}

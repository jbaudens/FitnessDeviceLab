import Foundation

public struct FileNameGenerator {
    public static func generate(metadata: ExportMetadata, startTime: Date, extension ext: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let dateString = formatter.string(from: startTime)
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "Z", with: "")
        
        var components: [String] = []
        
        // 1. Workout Name (Sanitize for file system)
        let sanitizedWorkoutName = metadata.workoutName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        components.append(sanitizedWorkoutName)
        
        // 2. Power Meter Name
        if let pwr = metadata.powerMeterName, !pwr.isEmpty {
            components.append(pwr.replacingOccurrences(of: " ", with: "_"))
        }
        
        // 3. HRM Name
        if let hrm = metadata.hrmName, !hrm.isEmpty {
            components.append(hrm.replacingOccurrences(of: " ", with: "_"))
        }
        
        // 4. Date/Time
        components.append(dateString)
        
        let filename = components.joined(separator: "_")
        return "\(filename).\(ext)"
    }
}

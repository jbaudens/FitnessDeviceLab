import Foundation

public struct Trackpoint: Identifiable, Sendable, Codable {
    public let id: UUID
    public let time: Date
    public let hr: Int?
    public let power: Int?
    public let cadence: Int?
    public let altitude: Double?
    public let speed: Double?
    public let powerBalance: Double?
    public let dfaAlpha1: Double?
    public let rrIntervals: [Double]

    public init(id: UUID = UUID(), time: Date, hr: Int? = nil, power: Int? = nil, cadence: Int? = nil, altitude: Double? = nil, speed: Double? = nil, powerBalance: Double? = nil, dfaAlpha1: Double? = nil, rrIntervals: [Double] = []) {
        self.id = id
        self.time = time
        self.hr = hr
        self.power = power
        self.cadence = cadence
        self.altitude = altitude
        self.speed = speed
        self.powerBalance = powerBalance
        self.dfaAlpha1 = dfaAlpha1
        self.rrIntervals = rrIntervals
    }
}

public struct Lap: Identifiable, Sendable, Codable {
    public let id: UUID
    public let index: Int
    public let startTime: Date
    public var endTime: Date?
    public let type: WorkoutStepType
    public var activeDuration: TimeInterval = 0

    public var duration: TimeInterval {
        return activeDuration
    }

    public init(id: UUID = UUID(), index: Int, startTime: Date, type: WorkoutStepType) {
        self.id = id
        self.index = index
        self.startTime = startTime
        self.type = type
    }
}

public struct ExportMetadata: Sendable {
    public let workoutName: String
    public let powerMeterName: String?
    public let hrmName: String?
    
    public init(workoutName: String, powerMeterName: String? = nil, hrmName: String? = nil) {
        self.workoutName = workoutName
        self.powerMeterName = powerMeterName
        self.hrmName = hrmName
    }
}

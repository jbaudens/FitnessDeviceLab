import Foundation

public struct Trackpoint: Identifiable, Sendable {
    public let id = UUID()
    public let time: Date
    public let hr: Int?
    public let power: Int?
    public let cadence: Int?
    public let altitude: Double?
    public let powerBalance: Double?
    public let rrIntervals: [Double]

    public init(time: Date, hr: Int? = nil, power: Int? = nil, cadence: Int? = nil, altitude: Double? = nil, powerBalance: Double? = nil, rrIntervals: [Double] = []) {
        self.time = time
        self.hr = hr
        self.power = power
        self.cadence = cadence
        self.altitude = altitude
        self.powerBalance = powerBalance
        self.rrIntervals = rrIntervals
    }
}

public struct Lap: Identifiable, Sendable {
    public let id = UUID()
    public let index: Int
    public let startTime: Date
    public var endTime: Date?
    public let type: WorkoutStepType
    public var activeDuration: TimeInterval = 0

    public var duration: TimeInterval {
        return activeDuration
    }

    public init(index: Int, startTime: Date, type: WorkoutStepType) {
        self.index = index
        self.startTime = startTime
        self.type = type
    }
}

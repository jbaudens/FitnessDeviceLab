import Foundation

public enum AppError: LocalizedError, Sendable {
    case bluetooth(BluetoothError)
    case export(ExportError)
    case workout(WorkoutError)
    case unknown(String)

    public enum BluetoothError: Sendable {
        case poweredOff
        case unauthorized
        case connectionFailed(String)
        case unexpectedDisconnect(String)
    }

    public enum ExportError: Sendable {
        case failedToGenerate(String)
        case noDataToExport
        case storageFull
    }

    public enum WorkoutError: Sendable {
        case invalidFile
        case failedToStart(String)
        case sessionTooShort
    }

    public var errorDescription: String? {
        switch self {
        case .bluetooth(let error):
            switch error {
            case .poweredOff: return "Bluetooth is turned off. Please enable it in Settings."
            case .unauthorized: return "Bluetooth permission denied. Please allow it in Settings."
            case .connectionFailed(let name): return "Failed to connect to \(name)."
            case .unexpectedDisconnect(let name): return "Lost connection to \(name)."
            }
        case .export(let error):
            switch error {
            case .failedToGenerate(let msg): return "Export failed: \(msg)"
            case .noDataToExport: return "No sensor data recorded. Session was not saved."
            case .storageFull: return "Not enough storage space to save the file."
            }
        case .workout(let error):
            switch error {
            case .invalidFile: return "The workout file is corrupted or unsupported."
            case .failedToStart(let msg): return "Could not start workout: \(msg)"
            case .sessionTooShort: return "The session was too short to be recorded."
            }
        case .unknown(let msg):
            return "An unexpected error occurred: \(msg)"
        }
    }
}

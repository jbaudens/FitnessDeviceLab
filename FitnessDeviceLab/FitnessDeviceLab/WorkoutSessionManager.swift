import Foundation
import Combine

class WorkoutSessionManager: ObservableObject {
    @Published var hrDeviceAId: UUID?
    @Published var powerDeviceAId: UUID?
    
    @Published var hrDeviceBId: UUID?
    @Published var powerDeviceBId: UUID?
    
    @Published var isRecording = false
    @Published var sessionStartTime: Date?
    
    @Published var activeProfile: ActivityProfile = .defaultProfile
    
    @Published var selectedWorkout: StructuredWorkout?
    
    public var recorderA = SessionRecorder()
    public var recorderB = SessionRecorder()
    
    @Published var exportedFiles: [URL] = []
    
    func startWorkout(devices: [DiscoveredPeripheral]) {
        recorderA.hrDevice = devices.first { $0.id == hrDeviceAId }
        recorderA.powerDevice = devices.first { $0.id == powerDeviceAId }
        
        recorderB.hrDevice = devices.first { $0.id == hrDeviceBId }
        recorderB.powerDevice = devices.first { $0.id == powerDeviceBId }
        
        // We only start a recorder if it actually has devices selected
        if recorderA.hrDevice != nil || recorderA.powerDevice != nil {
            recorderA.start()
        }
        
        if recorderB.hrDevice != nil || recorderB.powerDevice != nil {
            recorderB.start()
        }
        
        sessionStartTime = Date()
        isRecording = true
    }
    
    func stopWorkout() {
        isRecording = false
        
        var files: [URL] = []
        if let urlA = recorderA.stop(label: "ProfileA") { files.append(urlA) }
        if let urlB = recorderB.stop(label: "ProfileB") { files.append(urlB) }
        
        if !files.isEmpty {
            exportedFiles = files
        }
    }
}

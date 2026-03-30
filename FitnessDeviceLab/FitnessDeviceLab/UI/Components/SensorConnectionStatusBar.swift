import SwiftUI

struct SensorConnectionStatusBar: View {
    let recorderA: SessionRecorder
    let recorderB: SessionRecorder
    let trainer: ControllableTrainer?
    
    var body: some View {
        HStack(spacing: 16) {
            let hr = (recorderA.hrSource ?? recorderB.hrSource)
            if hr != nil {
                statusIcon(systemName: "heart.fill", isConnected: hr?.isConnected ?? false, color: .red)
            }
            
            let pwr = (recorderA.powerSource ?? recorderB.powerSource)
            if pwr != nil {
                statusIcon(systemName: "bolt.fill", isConnected: pwr?.isConnected ?? false, color: .orange)
            }
            
            let cad = (recorderA.cadenceSource ?? recorderB.cadenceSource)
            if cad != nil {
                statusIcon(systemName: "bicycle", isConnected: cad?.isConnected ?? false, color: .blue)
            }
            
            if let trainer = trainer {
                statusIcon(systemName: "dial.low.fill", isConnected: trainer.isConnected, color: .purple)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func statusIcon(systemName: String, isConnected: Bool, color: Color) -> some View {
        Image(systemName: systemName)
            .foregroundColor(isConnected ? color : .gray.opacity(0.5))
            .opacity(isConnected ? 1.0 : 0.5)
            .overlay(
                Group {
                    if !isConnected {
                        Image(systemName: "line.diagonal")
                            .foregroundColor(.red)
                    }
                }
            )
            .font(.caption)
    }
}

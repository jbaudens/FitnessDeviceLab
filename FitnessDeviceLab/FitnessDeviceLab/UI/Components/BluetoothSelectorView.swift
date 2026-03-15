import SwiftUI

struct BluetoothSelectorView: View {
    @State private var useSimulation = false
    @State private var realManager = BluetoothManager.shared
    @State private var simManager = SimulatedBluetoothProvider()
    
    var body: some View {
        Group {
            if useSimulation {
                ContentView()
                    .environment(\.bluetoothProvider, simManager)
            } else {
                ContentView()
                    .environment(\.bluetoothProvider, realManager)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                useSimulation.toggle()
            } label: {
                Image(systemName: useSimulation ? "cpu.fill" : "antenna.radiowaves.left.and.right")
                    .padding()
                    .background(useSimulation ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
    }
}

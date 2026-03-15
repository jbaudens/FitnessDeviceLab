import SwiftUI

struct BluetoothSelectorView: View {
    @Bindable var devicesViewModel: DevicesViewModel
    @Bindable var workoutPlayerViewModel: WorkoutPlayerViewModel
    
    @Environment(BluetoothManager.self) var bluetoothManager
    
    var body: some View {
        ContentView(
            devicesViewModel: devicesViewModel,
            workoutPlayerViewModel: workoutPlayerViewModel
        )
    }
}

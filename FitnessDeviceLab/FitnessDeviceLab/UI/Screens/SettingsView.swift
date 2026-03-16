import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    
    init(settings: SettingsManager) {
        _viewModel = State(initialValue: SettingsViewModel(settings: settings))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        List {
            Section("User Profile") {
                HStack {
                    Text("FTP (Watts)")
                    Spacer()
                    TextField("250", text: $vm.userFTP)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: vm.userFTP) { _, newValue in
                    vm.updateFTP(newValue)
                }
                
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("75", text: $vm.userWeight)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: vm.userWeight) { _, newValue in
                    vm.updateWeight(newValue)
                }

                HStack {
                    Text("Max Heart Rate (BPM)")
                    Spacer()
                    TextField("190", text: $vm.maxHR)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                .onChange(of: vm.maxHR) { _, newValue in
                    vm.updateMaxHR(newValue)
                }

                HStack {
                    Text("LTHR (BPM)")
                    Spacer()
                    TextField("170", text: $vm.userLTHR)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                .onChange(of: vm.userLTHR) { _, newValue in
                    vm.updateUserLTHR(newValue)
                }
            }
            
            Section("Altitude Settings") {
                HStack {
                    Text("Training Altitude (m)")
                    Spacer()
                    TextField("0", text: $vm.ftpAltitude)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: vm.ftpAltitude) { _, newValue in
                    vm.updateFTPAltitude(newValue)
                }
                
                Toggle("Manual Altitude Override", isOn: $vm.useAltitudeOverride)
                    .onChange(of: vm.useAltitudeOverride) { _, newValue in
                        vm.updateAltitudeOverrideToggle(newValue)
                    }
                
                if vm.useAltitudeOverride {
                    HStack {
                        Text("Fixed Altitude (m)")
                        Spacer()
                        TextField("500", text: $vm.altitudeOverride)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    .onChange(of: vm.altitudeOverride) { _, newValue in
                        vm.updateAltitudeOverrideValue(newValue)
                    }
                }
            }
            
            Section {
                Button("Reset to Defaults") {
                    vm.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profile & Environment")
    }
}

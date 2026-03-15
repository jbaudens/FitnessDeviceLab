import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) var settings
    
    // Local state to avoid layout loops during typing
    @State private var userFTP: String = ""
    @State private var userWeight: String = ""
    @State private var maxHR: String = ""
    @State private var userLTHR: String = ""
    @State private var ftpAltitude: String = ""
    @State private var altitudeOverride: String = ""
    @State private var useAltitudeOverride: Bool = false
    
    var body: some View {
        @Bindable var settings = settings
        List {
            Section("User Profile") {
                HStack {
                    Text("FTP (Watts)")
                    Spacer()
                    TextField("250", text: $userFTP)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: userFTP) { _, newValue in
                    if let val = Double(newValue) {
                        settings.userFTP = val
                    }
                }
                
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("75", text: $userWeight)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: userWeight) { _, newValue in
                    if let val = Double(newValue) {
                        settings.userWeight = val
                    }
                }

                HStack {
                    Text("Max Heart Rate (BPM)")
                    Spacer()
                    TextField("190", text: $maxHR)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                .onChange(of: maxHR) { _, newValue in
                    if let val = Int(newValue) {
                        settings.maxHR = val
                    }
                }

                HStack {
                    Text("LTHR (BPM)")
                    Spacer()
                    TextField("170", text: $userLTHR)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                .onChange(of: userLTHR) { _, newValue in
                    if let val = Int(newValue) {
                        settings.userLTHR = val
                    }
                }
            }
            
            Section("Altitude Settings") {
                HStack {
                    Text("Training Altitude (m)")
                    Spacer()
                    TextField("0", text: $ftpAltitude)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .onChange(of: ftpAltitude) { _, newValue in
                    if let val = Double(newValue) {
                        settings.ftpAltitude = val
                    }
                }
                
                Toggle("Manual Altitude Override", isOn: $useAltitudeOverride)
                    .onChange(of: useAltitudeOverride) { _, newValue in
                        if !newValue {
                            settings.altitudeOverride = nil
                        } else if let val = Double(altitudeOverride) {
                            settings.altitudeOverride = val
                        }
                    }
                
                if useAltitudeOverride {
                    HStack {
                        Text("Fixed Altitude (m)")
                        Spacer()
                        TextField("500", text: $altitudeOverride)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    .onChange(of: altitudeOverride) { _, newValue in
                        if let val = Double(newValue) {
                            settings.altitudeOverride = val
                        }
                    }
                }
            }
            
            Section {
                Button("Reset to Defaults") {
                    settings.userFTP = 200
                    settings.userWeight = 75
                    settings.ftpAltitude = 0
                    settings.altitudeOverride = nil
                    syncLocalState()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profile & Environment")
        .onAppear {
            syncLocalState()
        }
    }
    
    private func syncLocalState() {
        userFTP = String(format: "%.0f", settings.userFTP)
        userWeight = String(format: "%.1f", settings.userWeight)
        maxHR = String(format: "%d", settings.maxHR)
        userLTHR = String(format: "%d", settings.userLTHR)
        ftpAltitude = String(format: "%.0f", settings.ftpAltitude)
        if let over = settings.altitudeOverride {
            altitudeOverride = String(format: "%.0f", over)
            useAltitudeOverride = true
        } else {
            altitudeOverride = ""
            useAltitudeOverride = false
        }
    }
}

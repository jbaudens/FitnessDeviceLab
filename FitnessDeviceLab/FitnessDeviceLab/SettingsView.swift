import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    // Use local state to avoid real-time UserDefaults writes while typing
    @State private var localFTP: Double = 250.0
    @State private var localMaxHR: Int = 190
    @State private var localAltitude: Double = 0.0
    @State private var localWeight: Double = 75.0
    @State private var localFTPAltitude: Double = 0.0
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("FTP")
                    Spacer()
                    TextField("Watts", value: $localFTP, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: localFTP) { newValue in
                            settings.userFTP = newValue
                        }
                }
                
                HStack {
                    Text("FTP Altitude")
                    Spacer()
                    TextField("Meters", value: $localFTPAltitude, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: localFTPAltitude) { newValue in
                            settings.ftpAltitude = newValue
                        }
                    Text("m")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("kg", value: $localWeight, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: localWeight) { newValue in
                            settings.userWeight = newValue
                        }
                    Text("kg")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Max Heart Rate")
                    Spacer()
                    TextField("BPM", value: $localMaxHR, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: localMaxHR) { newValue in
                            settings.maxHR = newValue
                        }
                }
            } header: {
                Text("User Profile")
            } footer: {
                Text("FTP Altitude is the elevation where your FTP was tested. This allows for accurate performance normalization at different altitudes.")
            }
            
            Section {
                HStack {
                    Text("Default Altitude")
                    Spacer()
                    TextField("Meters", value: $localAltitude, format: .number)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: localAltitude) { newValue in
                            settings.altitudeOverride = newValue
                        }
                    Text("m")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Environment")
            } footer: {
                Text("This altitude will be used when GPS data is unavailable (e.g., indoor training or Mac Mini).")
            }
            
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            localFTP = settings.userFTP
            localMaxHR = settings.maxHR
            localAltitude = settings.altitudeOverride
            localWeight = settings.userWeight
            localFTPAltitude = settings.ftpAltitude
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

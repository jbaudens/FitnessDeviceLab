import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    // Use local state to avoid real-time UserDefaults writes while typing
    @State private var localFTP: Double = 250.0
    @State private var localMaxHR: Int = 190
    
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
                    Text("Max HR")
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
                Text("FTP is used for NP®, IF®, and TSS calculations. Max HR is used for intensity analysis.")
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
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var showingResetConfirmation = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(settings: SettingsManager) {
        _viewModel = State(initialValue: SettingsViewModel(settings: settings))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        
        Group {
            if horizontalSizeClass == .regular {
                // iPad / Mac: Two-column layout
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            profileSection(vm: viewModel)
                            environmentSection(vm: viewModel)
                            
                            Button(role: .destructive) {
                                showingResetConfirmation = true
                            } label: {
                                Text("Reset to Defaults")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 12)
                        }
                        .padding(24)
                        .frame(maxWidth: 500)
                    }
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            zoneTable(title: "Power Zones (Coggan)", ftp: viewModel.settings.userFTP, lthr: nil)
                            zoneTable(title: "Heart Rate Zones (LTHR)", ftp: nil, lthr: viewModel.settings.userLTHR)
                        }
                        .padding(24)
                    }
                    .background(Color.secondary.opacity(0.05))
                }
            } else {
                // iPhone: Standard single-column list
                List {
                    Section {
                        profileRows(vm: viewModel)
                    } header: {
                        Text("Physical Profile")
                    } footer: {
                        if viewModel.settings.userWeight > 0 {
                            Text("Current Power-to-Weight Ratio: \(String(format: "%.2f", viewModel.settings.userFTP / viewModel.settings.userWeight)) W/kg")
                        }
                    }
                    
                    Section {
                        environmentRows(vm: viewModel)
                    } header: {
                        Text("Environmental Conditions")
                    }
                    
                    Section {
                        NavigationLink("View Power Zones") {
                            ScrollView {
                                zoneTable(title: "Power Zones (Coggan)", ftp: viewModel.settings.userFTP, lthr: nil)
                                    .padding()
                            }
                            .navigationTitle("Power Zones")
                        }
                        NavigationLink("View HR Zones") {
                            ScrollView {
                                zoneTable(title: "Heart Rate Zones (LTHR)", ftp: nil, lthr: viewModel.settings.userLTHR)
                                    .padding()
                            }
                            .navigationTitle("HR Zones")
                        }
                    } header: {
                        Text("Zones")
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingResetConfirmation = true
                        } label: {
                            Text("Reset All Settings")
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset All Settings?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset to Defaults", role: .destructive) {
                viewModel.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all profile and environment settings to their default values.")
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func profileSection(vm: SettingsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            headerLabel("Physical Profile", icon: "person.fill")
            VStack(spacing: 12) {
                profileRows(vm: vm)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            
            if vm.settings.userWeight > 0 {
                HStack {
                    Text("Power-to-Weight Ratio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.2f", vm.settings.userFTP / vm.settings.userWeight)) W/kg")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private func environmentSection(vm: SettingsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            headerLabel("Environment", icon: "mountain.2.fill")
            VStack(spacing: 12) {
                environmentRows(vm: vm)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Row Reusable Parts
    
    @ViewBuilder
    private func profileRows(vm: SettingsViewModel) -> some View {
        @Bindable var settings = vm.settings
        stepperInputRow(title: "FTP", subtitle: "Functional Threshold Power", value: $settings.userFTP, unit: "W", range: 50...600, step: 1)
        Divider()
        stepperInputRow(title: "Weight", subtitle: "Body weight for physics", value: $settings.userWeight, unit: "kg", range: 30...200, step: 0.1)
        Divider()
        stepperInputRow(title: "LTHR", subtitle: "Lactate Threshold HR", value: intBinding($settings.userLTHR), unit: "BPM", range: 80...220, step: 1)
        Divider()
        stepperInputRow(title: "Max HR", subtitle: "Your absolute maximum HR", value: intBinding($settings.maxHR), unit: "BPM", range: 100...240, step: 1)
    }
    
    @ViewBuilder
    private func environmentRows(vm: SettingsViewModel) -> some View {
        @Bindable var settings = vm.settings
        @Bindable var viewModel = vm
        stepperInputRow(title: "Training Alt.", subtitle: "Elevation where FTP was set", value: $settings.ftpAltitude, unit: "m", range: 0...4000, step: 10)
        Divider()
        Toggle("Manual Altitude Override", isOn: $viewModel.useAltitudeOverride)
            .font(.subheadline.weight(.medium))
            .onChange(of: viewModel.useAltitudeOverride) { _, newValue in
                viewModel.updateAltitudeOverrideToggle(newValue)
            }
        
        if viewModel.useAltitudeOverride {
            stepperInputRow(title: "Fixed Alt.", subtitle: "Forced elevation value", value: altitudeBinding($settings.altitudeOverride), unit: "m", range: 0...5000, step: 10)
                .padding(.leading, 12)
        }
    }
    
    // MARK: - Components
    
    private func headerLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title.uppercased())
        }
        .font(.system(size: 12, weight: .black))
        .foregroundColor(.secondary)
    }
    
    private func stepperInputRow(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        unit: String,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Manual Entry / Display
                TextField("", value: value, format: .number.precision(.fractionLength(step < 1 ? 1 : 0)))
                    .multilineTextAlignment(.center)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .frame(width: 60)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                
                Text(unit)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
                    #if os(macOS)
                    .controlSize(.small)
                    #endif
            }
        }
    }
    
    @ViewBuilder
    private func zoneTable(title: String, ftp: Double?, lthr: Int?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 0) {
                zoneHeader()
                
                ForEach(WorkoutZone.allCases) { zone in
                    zoneRow(zone: zone, ftp: ftp, lthr: lthr)
                }
            }
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func zoneHeader() -> some View {
        HStack {
            Text("Zone").frame(width: 80, alignment: .leading)
            Text("Name").frame(maxWidth: .infinity, alignment: .leading)
            Text("Range").frame(width: 100, alignment: .trailing)
        }
        .font(.caption.bold())
        .foregroundColor(.secondary)
        .padding(.bottom, 8)
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private func zoneRow(zone: WorkoutZone, ftp: Double?, lthr: Int?) -> some View {
        HStack {
            // Color Pill
            HStack {
                Circle()
                    .fill(zone.color)
                    .frame(width: 8, height: 8)
                Text("Z\(zone.rawValue)")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
            }
            .frame(width: 80, alignment: .leading)
            
            Text(zone.name)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let f = ftp {
                let range = zone.powerRange(ftp: f)
                Text(range.max != nil ? "\(range.min)–\(range.max!) W" : ">\(range.min) W")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 100, alignment: .trailing)
            } else if let l = lthr {
                let range = zone.hrRange(lthr: l)
                Text(range.max != nil ? "\(range.min)–\(range.max!) bpm" : ">\(range.min) bpm")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(zone.rawValue % 2 == 0 ? Color.clear : Color.secondary.opacity(0.03))
    }
    
    // MARK: - Helpers
    
    private func intBinding(_ binding: Binding<Int>) -> Binding<Double> {
        Binding(
            get: { Double(binding.wrappedValue) },
            set: { binding.wrappedValue = Int(round($0)) }
        )
    }
    
    private func altitudeBinding(_ binding: Binding<Double?>) -> Binding<Double> {
        Binding(
            get: { binding.wrappedValue ?? 0.0 },
            set: { binding.wrappedValue = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: SettingsManager())
    }
}

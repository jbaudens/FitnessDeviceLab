import SwiftUI

struct SensorSetCard: View {
    let title: String
    let subtitle: String
    let color: Color
    @Bindable var recorder: SessionRecorder
    let hrSensors: [HeartRateSensor]
    let pwrSensors: [PowerSensor]
    let cadSensors: [CadenceSensor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                // HR Picker
                HStack {
                    Label {
                        Text("Heart Rate").font(.subheadline)
                    } icon: {
                        Image(systemName: "heart.fill").foregroundColor(.red)
                    }
                    Spacer()
                    Picker("HR", selection: $recorder.hrSource) {
                        Text("Unassigned").tag(nil as HeartRateSensor?)
                        ForEach(hrSensors, id: \.id) { sensor in
                            Text(sensor.name).tag(sensor as HeartRateSensor?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityIdentifier(title.contains("(A)") ? "hr_picker_a" : "hr_picker_b")
                }
                
                // Power Picker
                HStack {
                    Label {
                        Text("Power Meter").font(.subheadline)
                    } icon: {
                        Image(systemName: "bolt.fill").foregroundColor(.yellow)
                    }
                    Spacer()
                    Picker("Power", selection: $recorder.powerSource) {
                        Text("Unassigned").tag(nil as PowerSensor?)
                        ForEach(pwrSensors, id: \.id) { sensor in
                            Text(sensor.name).tag(sensor as PowerSensor?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityIdentifier(title.contains("(A)") ? "pwr_picker_a" : "pwr_picker_b")
                }
                
                // Cadence Picker
                HStack {
                    Label {
                        Text("Cadence Sensor").font(.subheadline)
                    } icon: {
                        Image(systemName: "bicycle").foregroundColor(.blue)
                    }
                    Spacer()
                    Picker("Cadence", selection: $recorder.cadenceSource) {
                        Text("Unassigned").tag(nil as CadenceSensor?)
                        ForEach(cadSensors, id: \.id) { sensor in
                            Text(sensor.name).tag(sensor as CadenceSensor?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityIdentifier(title.contains("(A)") ? "cad_picker_a" : "cad_picker_b")
                }
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

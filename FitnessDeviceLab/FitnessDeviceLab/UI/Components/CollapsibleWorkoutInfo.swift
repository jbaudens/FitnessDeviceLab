import SwiftUI

struct CollapsibleWorkoutInfo: View {
    @Binding var name: String
    @Binding var description: String
    @State private var isExpanded = false
    var isNewWorkout: Bool
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Workout Name", text: $name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .submitLabel(.done)
                    
                    if !isExpanded && !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DESCRIPTION")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $description)
                        .font(.subheadline)
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                    
                    if !isNewWorkout {
                        Divider().padding(.vertical, 4)
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Workout", systemImage: "trash")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CollapsibleWorkoutInfo(
        name: .constant("Threshold Over-Unders"),
        description: .constant("A classic session to improve FTP by oscillating around threshold power."),
        isNewWorkout: false,
        onDelete: {}
    )
    .padding()
}

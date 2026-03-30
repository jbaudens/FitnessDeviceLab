import SwiftUI

struct ActivityProfileSelector: View {
    @Binding var selectedProfile: ActivityProfile
    let profiles: [ActivityProfile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY PROFILE")
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isSelected: selectedProfile.id == profile.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedProfile = profile
                            }
                            #if os(iOS)
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            #endif
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

struct ProfileCard: View {
    let profile: ActivityProfile
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: profile.iconName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isSelected ? .white : profile.color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? profile.color : profile.color.opacity(0.1))
                )
            
            Text(profile.name.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(width: 100, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(isSelected ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? profile.color : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

#Preview {
    ActivityProfileSelector(
        selectedProfile: .constant(.defaultProfile),
        profiles: ActivityProfile.availableProfiles
    )
}

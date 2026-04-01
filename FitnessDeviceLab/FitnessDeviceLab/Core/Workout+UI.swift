import SwiftUI

extension WorkoutZone {
    public var color: Color {
        switch self {
        case .z1: return .gray
        case .z2: return .blue
        case .z3: return .green
        case .z4: return .yellow
        case .z5: return .orange
        case .z6: return .red
        case .z7: return .purple
        }
    }
}

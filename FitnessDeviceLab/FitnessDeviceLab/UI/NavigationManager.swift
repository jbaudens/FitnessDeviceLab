import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case devices = "Devices"
    case library = "Library"
    case workout = "Workout"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .devices: return "antenna.radiowaves.left.and.right"
        case .library: return "books.vertical"
        case .workout: return "play.circle"
        case .settings: return "gear"
        }
    }
}

@Observable
class NavigationManager {
    var selectedTab: AppTab? = .devices
    var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    var isSidebarCollapsed: Bool = false
    
    // Track workout state to auto-collapse sidebar
    var isWorkoutActive: Bool = false {
        didSet {
            if isWorkoutActive {
                sidebarVisibility = .detailOnly
            } else {
                sidebarVisibility = .automatic
            }
        }
    }
}

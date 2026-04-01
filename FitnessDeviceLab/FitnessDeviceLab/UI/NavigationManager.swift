import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable {
    case devices = "Devices"
    case library = "Library"
    case workout = "Workout"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .devices: return "antenna.radiowaves.left.and.right"
        case .library: return "books.vertical"
        case .workout: return "play.circle"
        case .settings: return "gear"
        }
    }
}

@Observable
public class NavigationManager {
    public var selectedTab: AppTab? = .devices
    public var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    public var isSidebarCollapsed: Bool = false
    
    public init() {}
    
    // Track workout state to auto-collapse sidebar
    public var isWorkoutActive: Bool = false {
        didSet {
            if isWorkoutActive {
                sidebarVisibility = .detailOnly
            } else {
                sidebarVisibility = .automatic
            }
        }
    }
}

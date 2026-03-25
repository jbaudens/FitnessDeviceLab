import Testing
import SwiftUI
@testable import FitnessDeviceLab

@MainActor
struct NavigationManagerTests {

    @Test func testInitialState() async throws {
        let manager = NavigationManager()
        #expect(manager.selectedTab == .devices)
        #expect(manager.sidebarVisibility == .automatic)
        #expect(!manager.isSidebarCollapsed)
        #expect(!manager.isWorkoutActive)
    }

    @Test func testWorkoutActiveChangesSidebarVisibility() async throws {
        let manager = NavigationManager()
        manager.isWorkoutActive = true
        #expect(manager.sidebarVisibility == .detailOnly)
    }
}

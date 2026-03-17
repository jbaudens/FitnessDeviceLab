import SwiftUI

// MARK: - Semantic View Modifiers
extension View {
    /// Hides the navigation bar on iOS/iPadOS while keeping it visible on macOS.
    @ViewBuilder
    func hideNavigationBarOnMobile() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
    
    /// Applies the standard grouped list style on iOS and inset on macOS.
    @ViewBuilder
    func adaptiveListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.grouped)
        #else
        self.listStyle(.inset)
        #endif
    }
    
    /// Sets the navigation title display mode to inline on iOS, and does nothing on macOS.
    @ViewBuilder
    func inlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: - Semantic Toolbar Placements
extension ToolbarItemPlacement {
    static var adaptiveTrailing: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .confirmationAction
        #endif
    }
}

// MARK: - Cross-Platform Semantic Colors
extension Color {
    static var systemGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    static var secondarySystemGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    static var systemBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

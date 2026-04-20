import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case french = "fr"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .french: return "Français"
        }
    }
    
    public var locale: Locale? {
        guard self != .system else { return nil }
        return Locale(identifier: self.rawValue)
    }
}

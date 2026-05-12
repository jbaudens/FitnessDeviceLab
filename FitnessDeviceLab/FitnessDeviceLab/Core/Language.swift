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
    
    public var locale: Locale {
        switch self {
        case .system: return .current
        case .english: return Locale(identifier: "en")
        case .french: return Locale(identifier: "fr")
        }
    }
}

import Foundation
import Observation

@Observable
public class ErrorManager {
    public var currentError: AppError?
    
    public init() {}
    
    @MainActor
    public func report(_ error: AppError) {
        self.currentError = error
    }
    
    @MainActor
    public func dismiss() {
        self.currentError = nil
    }
}

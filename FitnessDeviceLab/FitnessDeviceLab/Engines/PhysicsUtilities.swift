import Foundation

public struct PhysicsUtilities {
    /// Estimated speed in m/s based on Power (W) and Weight (kg)
    /// Simple physics model assuming flat road, no wind, and typical rolling resistance/drag.
    nonisolated public static func estimateSpeed(power: Double, totalWeight: Double) -> Double {
        guard power > 0 else { return 0 }
        
        // Constants for a typical road bike on flats
        let frontalArea = 0.5 // m^2
        let dragCoefficient = 0.63
        let airDensity = 1.225 // kg/m^3
        let rollingResistanceCoeff = 0.005
        let gravity = 9.81
        
        // P = (Rolling Resistance + Drag) * Speed
        // P = (Crr * m * g + 0.5 * Cd * A * rho * v^2) * v
        // This is a cubic equation: v^3 * (0.5*Cd*A*rho) + v * (Crr*m*g) - P = 0
        
        let a = 0.5 * dragCoefficient * frontalArea * airDensity
        let b = rollingResistanceCoeff * totalWeight * gravity
        
        // Simple iterative solver for v (Newton's method or binary search)
        var v = 5.0 // start guess 18km/h
        for _ in 0..<5 {
            let f = a * pow(v, 3) + b * v - power
            let df = 3 * a * pow(v, 2) + b
            v = v - f / df
        }
        
        return max(0, v)
    }
}

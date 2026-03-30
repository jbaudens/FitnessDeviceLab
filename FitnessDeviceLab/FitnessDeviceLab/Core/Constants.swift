import Foundation

public enum Constants {
    /// Physics & Environmental Constants
    nonisolated public enum Physics {
        /// Weight of a standard high-performance road bike (UCI minimum) in kg
        public static let defaultBikeWeight: Double = 6.8
        
        /// Air density at sea level (kg/m^3)
        public static let airDensity: Double = 1.225
        
        /// Acceleration due to gravity (m/s^2)
        public static let gravity: Double = 9.81
        
        /// Typical coefficient of rolling resistance for road tires
        public static let rollingResistanceCoeff: Double = 0.005
        
        /// Typical drag coefficient for a road cyclist
        public static let dragCoefficient: Double = 0.63
        
        /// Typical frontal area for a road cyclist (m^2)
        public static let frontalArea: Double = 0.5
    }
    
    /// Bluetooth & Protocol Constants
    nonisolated public enum BLE {
        /// Bluetooth Time Resolution for RR intervals and Crank timing (1/1024 seconds)
        public static let bleTimeResolution: Double = 1024.0
    }
}

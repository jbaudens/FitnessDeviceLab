import Foundation
import CoreLocation
import Observation

public class LocationManager: NSObject, Observation.Observable, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    public var currentAltitude: Double? // In meters
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // On Mac Mini or devices without proper hardware, location.altitude often returns 0.0 with high verticalAccuracy.
            // We only use the value if it's non-zero, allowing the system to fall back to the user's manual setting.
            if location.altitude != 0.0 {
                currentAltitude = location.altitude
            } else {
                currentAltitude = nil
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
        currentAltitude = nil
    }
}

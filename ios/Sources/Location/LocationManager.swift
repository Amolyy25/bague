import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var lastCoordinate: CLLocationCoordinate2D?
    @Published var lastAddress: String = "Localisation inconnue"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        
        manager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return lastCoordinate
    }
    
    func getFormattedLocation() -> String {
        guard let coordinate = lastCoordinate else {
            return "Localisation inconnue"
        }
        
        let lat = String(format: "%.6f", coordinate.latitude)
        let lon = String(format: "%.6f", coordinate.longitude)
        
        if !lastAddress.isEmpty && lastAddress != "Localisation inconnue" {
            return "📍 \(lastAddress)\n🌐 Coordonnées: \(lat), \(lon)\n🗺️ Carte: https://maps.apple.com/?ll=\(lat),\(lon)"
        } else {
            return "🌐 Coordonnées GPS: \(lat), \(lon)\n🗺️ Carte: https://maps.apple.com/?ll=\(lat),\(lon)"
        }
    }
    
    func getEmergencyLocationText() -> String {
        guard let coordinate = lastCoordinate else {
            return "🚨 ALERTE URGENCE\n⚠️ Localisation inconnue\n⏰ \(Date().formatted(date: .abbreviated, time: .shortened))"
        }
        
        let lat = String(format: "%.6f", coordinate.latitude)
        let lon = String(format: "%.6f", coordinate.longitude)
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        
        if !lastAddress.isEmpty && lastAddress != "Localisation inconnue" {
            return """
            🚨 ALERTE URGENCE
            ⚠️ J'ai besoin d'aide immédiatement !
            
            📍 Adresse: \(lastAddress)
            🌐 GPS: \(lat), \(lon)
            🗺️ Carte: https://maps.apple.com/?ll=\(lat),\(lon)
            
            ⏰ Heure: \(timestamp)
            📱 App: SafetyRing
            """
        } else {
            return """
            🚨 ALERTE URGENCE
            ⚠️ J'ai besoin d'aide immédiatement !
            
            🌐 Coordonnées GPS: \(lat), \(lon)
            🗺️ Carte: https://maps.apple.com/?ll=\(lat),\(lon)
            
            ⏰ Heure: \(timestamp)
            📱 App: SafetyRing
            """
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastCoordinate = location.coordinate
        
        // Reverse geocoding to get address
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.thoroughfare,
                        placemark.subThoroughfare,
                        placemark.postalCode,
                        placemark.locality,
                        placemark.administrativeArea
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    if !address.isEmpty {
                        self?.lastAddress = address
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLocationEnabled = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.isLocationEnabled = (status == .authorizedWhenInUse || status == .authorizedAlways)
            
            if self.isLocationEnabled {
                self.startUpdatingLocation()
            }
        }
    }
}



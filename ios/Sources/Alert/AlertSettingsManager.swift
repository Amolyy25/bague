import Foundation
import SwiftUI

struct AlertSettings: Codable {
    var enableVibration: Bool = true
    var enableSound: Bool = true
    var enableSpeech: Bool = true
    var vibrationDuration: Double = 5.0
    var alertVolume: Double = 0.8
    var speechRate: Double = 0.5
    var speechVolume: Double = 0.7
    var preferredPlatform: MessagePlatform = .imessage
    var enableWhatsAppScraping: Bool = false
    var enableLocationSharing: Bool = true
    var enableEmergencyNumbers: Bool = true
}

final class AlertSettingsManager: ObservableObject {
    @Published var settings: AlertSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let settingsKey = "sr_alert_settings"
    
    init() {
        self.settings = AlertSettings()
        loadSettings()
    }
    
    // MARK: - Platform Management
    
    func setPreferredPlatform(_ platform: MessagePlatform) {
        settings.preferredPlatform = platform
    }
    
    func toggleWhatsAppScraping() {
        settings.enableWhatsAppScraping.toggle()
    }
    
    func isWhatsAppScrapingEnabled() -> Bool {
        return settings.enableWhatsAppScraping
    }
    
    // MARK: - Alert Features
    
    func toggleVibration() {
        settings.enableVibration.toggle()
    }
    
    func toggleSound() {
        settings.enableSound.toggle()
    }
    
    func toggleSpeech() {
        settings.enableSpeech.toggle()
    }
    
    func setVibrationDuration(_ duration: Double) {
        settings.vibrationDuration = max(1.0, min(10.0, duration))
    }
    
    func setAlertVolume(_ volume: Double) {
        settings.alertVolume = max(0.0, min(1.0, volume))
    }
    
    func setSpeechRate(_ rate: Double) {
        settings.speechRate = max(0.1, min(1.0, rate))
    }
    
    func setSpeechVolume(_ volume: Double) {
        settings.speechVolume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Privacy Settings
    
    func toggleLocationSharing() {
        settings.enableLocationSharing.toggle()
    }
    
    func toggleEmergencyNumbers() {
        settings.enableEmergencyNumbers.toggle()
    }
    
    // MARK: - Data Persistence
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let loadedSettings = try? JSONDecoder().decode(AlertSettings.self, from: data) {
            settings = loadedSettings
        }
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() {
        settings = AlertSettings()
        saveSettings()
    }
    
    // MARK: - Export/Import Settings
    
    func exportSettings() -> Data? {
        return try? JSONEncoder().encode(settings)
    }
    
    func importSettings(from data: Data) -> Bool {
        do {
            let importedSettings = try JSONDecoder().decode(AlertSettings.self, from: data)
            settings = importedSettings
            saveSettings()
            return true
        } catch {
            print("Erreur lors de l'import des paramètres: \(error)")
            return false
        }
    }
    
    // MARK: - Validation
    
    func validateSettings() -> [String] {
        var errors: [String] = []
        
        if settings.vibrationDuration < 1.0 || settings.vibrationDuration > 10.0 {
            errors.append("La durée de vibration doit être entre 1 et 10 secondes")
        }
        
        if settings.alertVolume < 0.0 || settings.alertVolume > 1.0 {
            errors.append("Le volume d'alerte doit être entre 0 et 1")
        }
        
        if settings.speechRate < 0.1 || settings.speechRate > 1.0 {
            errors.append("La vitesse de parole doit être entre 0.1 et 1.0")
        }
        
        if settings.speechVolume < 0.0 || settings.speechVolume > 1.0 {
            errors.append("Le volume de parole doit être entre 0 et 1")
        }
        
        return errors
    }
    
    // MARK: - Platform-Specific Settings
    
    func getPlatformSettings(for platform: MessagePlatform) -> [String: Any] {
        switch platform {
        case .imessage:
            return [
                "name": "iMessage (SMS)",
                "description": "Messages automatiques via l'application Messages d'iOS",
                "isAlwaysAvailable": true,
                "requiresConsent": false,
                "supportsLocation": true,
                "supportsTemplates": true
            ]
        case .whatsapp:
            return [
                "name": "WhatsApp",
                "description": "Messages automatiques via WhatsApp Web (mode expérimental)",
                "isAlwaysAvailable": false,
                "requiresConsent": true,
                "supportsLocation": true,
                "supportsTemplates": true,
                "warnings": [
                    "Risque de bannissement de compte",
                    "Fonctionnalité expérimentale",
                    "Utilisation responsable requise"
                ]
            ]
        }
    }
    
    // MARK: - Emergency Settings
    
    func getEmergencySettings() -> [String: Any] {
        return [
            "countdownDuration": settings.vibrationDuration,
            "enableVibration": settings.enableVibration,
            "enableSound": settings.enableSound,
            "enableSpeech": settings.enableSpeech,
            "locationSharing": settings.enableLocationSharing,
            "emergencyNumbers": settings.enableEmergencyNumbers,
            "preferredPlatform": settings.preferredPlatform.rawValue,
            "whatsAppScraping": settings.enableWhatsAppScraping
        ]
    }
    
    // MARK: - Accessibility Settings
    
    func getAccessibilitySettings() -> [String: Any] {
        return [
            "speechEnabled": settings.enableSpeech,
            "speechRate": settings.speechRate,
            "speechVolume": settings.speechVolume,
            "vibrationEnabled": settings.enableVibration,
            "vibrationDuration": settings.vibrationDuration,
            "soundEnabled": settings.enableSound,
            "soundVolume": settings.alertVolume
        ]
    }
}

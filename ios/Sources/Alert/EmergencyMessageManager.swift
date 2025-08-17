import Foundation
import CoreLocation

struct EmergencyTemplate: Codable, Identifiable {
    let id = UUID()
    var name: String
    var message: String
    var isActive: Bool
    var category: EmergencyCategory
    var customVariables: [String: String]
    
    enum EmergencyCategory: String, CaseIterable, Codable {
        case agression = "Agressions"
        case medical = "Urgence médicale"
        case accident = "Accident"
        case danger = "Danger immédiat"
        case custom = "Personnalisé"
        
        var icon: String {
            switch self {
            case .agression: return "exclamationmark.shield.fill"
            case .medical: return "cross.case.fill"
            case .accident: return "car.circle.fill"
            case .danger: return "flame.fill"
            case .custom: return "pencil.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .agression: return "red"
            case .medical: return "blue"
            case .accident: return "orange"
            case .danger: return "purple"
            case .custom: return "gray"
            }
        }
    }
}

final class EmergencyMessageManager: ObservableObject {
    @Published var templates: [EmergencyTemplate] = []
    @Published var customMessage: String = ""
    @Published var selectedTemplate: EmergencyTemplate?
    
    private let templatesKey = "sr_emergency_templates"
    private let customMessageKey = "sr_custom_message"
    
    init() {
        loadTemplates()
        loadCustomMessage()
        createDefaultTemplates()
    }
    
    private func createDefaultTemplates() {
        if templates.isEmpty {
            templates = [
                EmergencyTemplate(
                    name: "Agressions",
                    message: """
                    🚨 ALERTE URGENCE - AGRESSION
                    ⚠️ J'ai besoin d'aide immédiatement !
                    
                    📍 Adresse: {ADDRESS}
                    🌐 GPS: {GPS}
                    🗺️ Carte: {MAP_LINK}
                    
                    ⏰ Heure: {TIME}
                    📱 App: SafetyRing
                    🚔 Police: 17
                    🚑 SAMU: 15
                    """,
                    isActive: true,
                    category: .agression,
                    customVariables: [:]
                ),
                EmergencyTemplate(
                    name: "Urgence médicale",
                    message: """
                    🚨 ALERTE URGENCE MÉDICALE
                    ⚠️ Assistance médicale requise !
                    
                    📍 Adresse: {ADDRESS}
                    🌐 GPS: {GPS}
                    🗺️ Carte: {MAP_LINK}
                    
                    ⏰ Heure: {TIME}
                    📱 App: SafetyRing
                    🚑 SAMU: 15
                    🚒 Pompiers: 18
                    """,
                    isActive: true,
                    category: .medical,
                    customVariables: [:]
                ),
                EmergencyTemplate(
                    name: "Accident de la route",
                    message: """
                    🚨 ALERTE ACCIDENT DE LA ROUTE
                    ⚠️ Accident survenu, assistance requise !
                    
                    📍 Adresse: {ADDRESS}
                    🌐 GPS: {GPS}
                    🗺️ Carte: {MAP_LINK}
                    
                    ⏰ Heure: {TIME}
                    📱 App: SafetyRing
                    🚔 Police: 17
                    🚑 SAMU: 15
                    🚒 Pompiers: 18
                    """,
                    isActive: true,
                    category: .accident,
                    customVariables: [:]
                ),
                EmergencyTemplate(
                    name: "Danger immédiat",
                    message: """
                    🚨 ALERTE DANGER IMMÉDIAT
                    ⚠️ Situation dangereuse, évacuation requise !
                    
                    📍 Adresse: {ADDRESS}
                    🌐 GPS: {GPS}
                    🗺️ Carte: {MAP_LINK}
                    
                    ⏰ Heure: {TIME}
                    📱 App: SafetyRing
                    🚔 Police: 17
                    🚒 Pompiers: 18
                    """,
                    isActive: true,
                    category: .danger,
                    customVariables: [:]
                )
            ]
            saveTemplates()
        }
    }
    
    func generateEmergencyMessage(template: EmergencyTemplate, location: LocationManager) -> String {
        var message = template.message
        
        // Replace variables with actual values
        let coords = location.getCurrentLocation()
        let address = location.lastAddress
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        
        if let coordinate = coords {
            let lat = String(format: "%.6f", coordinate.latitude)
            let lon = String(format: "%.6f", coordinate.longitude)
            let mapLink = "https://maps.apple.com/?ll=\(lat),\(lon)"
            
            message = message.replacingOccurrences(of: "{ADDRESS}", with: address)
            message = message.replacingOccurrences(of: "{GPS}", with: "\(lat), \(lon)")
            message = message.replacingOccurrences(of: "{MAP_LINK}", with: mapLink)
        } else {
            message = message.replacingOccurrences(of: "{ADDRESS}", with: "Localisation inconnue")
            message = message.replacingOccurrences(of: "{GPS}", with: "Non disponible")
            message = message.replacingOccurrences(of: "{MAP_LINK}", with: "Non disponible")
        }
        
        message = message.replacingOccurrences(of: "{TIME}", with: timestamp)
        
        // Replace custom variables
        for (key, value) in template.customVariables {
            message = message.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        return message
    }
    
    func generateCustomMessage(location: LocationManager) -> String {
        if customMessage.isEmpty {
            return location.getEmergencyLocationText()
        }
        
        var message = customMessage
        
        // Replace variables in custom message
        let coords = location.getCurrentLocation()
        let address = location.lastAddress
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        
        if let coordinate = coords {
            let lat = String(format: "%.6f", coordinate.latitude)
            let lon = String(format: "%.6f", coordinate.longitude)
            let mapLink = "https://maps.apple.com/?ll=\(lat),\(lon)"
            
            message = message.replacingOccurrences(of: "{ADDRESS}", with: address)
            message = message.replacingOccurrences(of: "{GPS}", with: "\(lat), \(lon)")
            message = message.replacingOccurrences(of: "{MAP_LINK}", with: mapLink)
        } else {
            message = message.replacingOccurrences(of: "{ADDRESS}", with: "Localisation inconnue")
            message = message.replacingOccurrences(of: "{GPS}", with: "Non disponible")
            message = message.replacingOccurrences(of: "{MAP_LINK}", with: "Non disponible")
        }
        
        message = message.replacingOccurrences(of: "{TIME}", with: timestamp)
        
        return message
    }
    
    func addTemplate(_ template: EmergencyTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func updateTemplate(_ template: EmergencyTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }
    
    func deleteTemplate(_ template: EmergencyTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func toggleTemplate(_ template: EmergencyTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].isActive.toggle()
            saveTemplates()
        }
    }
    
    func updateCustomMessage(_ message: String) {
        customMessage = message
        saveCustomMessage()
    }
    
    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let loadedTemplates = try? JSONDecoder().decode([EmergencyTemplate].self, from: data) {
            templates = loadedTemplates
        }
    }
    
    private func saveCustomMessage() {
        UserDefaults.standard.set(customMessage, forKey: customMessageKey)
    }
    
    private func loadCustomMessage() {
        customMessage = UserDefaults.standard.string(forKey: customMessageKey) ?? ""
    }
}

import Foundation
import MessageUI
import UIKit

enum MessagePlatform: String, CaseIterable, Identifiable {
    case imessage = "iMessage"
    case whatsapp = "WhatsApp"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .imessage: return "message.fill"
        case .whatsapp: return "message.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .imessage: return "blue"
        case .whatsapp: return "green"
        }
    }
    
    var displayName: String {
        switch self {
        case .imessage: return "iMessage (SMS)"
        case .whatsapp: return "WhatsApp"
        }
    }
}

struct MessageRecipient: Identifiable, Codable {
    let id = UUID()
    var phoneNumber: String
    var name: String
    var platforms: [MessagePlatform]
    var isActive: Bool
    var isEmergency: Bool
    
    init(phoneNumber: String, name: String = "", platforms: [MessagePlatform] = [.imessage], isEmergency: Bool = false) {
        self.phoneNumber = phoneNumber
        self.name = name.isEmpty ? phoneNumber : name
        self.platforms = platforms
        self.isActive = true
        self.isEmergency = isEmergency
    }
}

final class MultiPlatformMessageManager: ObservableObject {
    @Published var recipients: [MessageRecipient] = []
    @Published var selectedPlatform: MessagePlatform = .imessage
    @Published var showingPlatformSelector = false
    @Published var hasUserConsent = false
    
    private let recipientsKey = "sr_message_recipients"
    private let consentKey = "sr_user_consent"
    
    init() {
        loadUserConsent()
        loadRecipients()
    }
    
    // MARK: - User Consent Management
    
    func setUserConsent(_ consent: Bool) {
        hasUserConsent = consent
        UserDefaults.standard.set(consent, forKey: consentKey)
        
        if consent {
            // Charger les destinataires par défaut
            loadDefaultRecipients()
        }
    }
    
    private func loadUserConsent() {
        hasUserConsent = UserDefaults.standard.bool(forKey: consentKey)
    }
    
    // MARK: - Recipient Management
    
    func addRecipient(_ recipient: MessageRecipient) {
        recipients.append(recipient)
        saveRecipients()
    }
    
    func updateRecipient(_ recipient: MessageRecipient) {
        if let index = recipients.firstIndex(where: { $0.id == recipient.id }) {
            recipients[index] = recipient
            saveRecipients()
        }
    }
    
    func removeRecipient(_ recipient: MessageRecipient) {
        recipients.removeAll { $0.id == recipient.id }
        saveRecipients()
    }
    
    func toggleRecipient(_ recipient: MessageRecipient) {
        if let index = recipients.firstIndex(where: { $0.id == recipient.id }) {
            recipients[index].isActive.toggle()
            saveRecipients()
        }
    }
    
    // MARK: - Message Sending
    
    func sendMessage(to recipient: MessageRecipient, message: String, platform: MessagePlatform) -> Bool {
        guard recipient.isActive && hasUserConsent else { return false }
        
        switch platform {
        case .imessage:
            return sendIMessage(to: recipient.phoneNumber, message: message)
        case .whatsapp:
            return sendWhatsAppMessage(to: recipient, message: message, useScraping: true)
        }
    }
    
    func sendMessageToAllRecipients(message: String, platform: MessagePlatform) {
        guard hasUserConsent else { return }
        
        let activeRecipients = recipients.filter { $0.isActive && $0.platforms.contains(platform) }
        
        for recipient in activeRecipients {
            _ = sendMessage(to: recipient, message: message, platform: platform)
        }
    }
    
    // MARK: - WhatsApp Scraping Support
    
    func sendWhatsAppMessage(to recipient: MessageRecipient, message: String, useScraping: Bool = true) -> Bool {
        if useScraping {
            // Utiliser le mode scraping WhatsApp
            return sendWhatsAppViaScraping(to: recipient.phoneNumber, message: message)
        } else {
            // Utiliser la méthode standard (fallback)
            return openWhatsApp(to: recipient.phoneNumber, message: message)
        }
    }
    
    private func sendWhatsAppViaScraping(to phoneNumber: String, message: String) -> Bool {
        // Cette fonction sera appelée par le WhatsAppScraperManager
        // Pour l'instant, on retourne false pour indiquer que le scraping n'est pas disponible
        print("WhatsApp scraping not available in this context")
        return false
    }
    
    // MARK: - iMessage Support
    
    private func sendIMessage(to phoneNumber: String, message: String) -> Bool {
        // This will be handled by the MessageComposeView in ContentView
        return MFMessageComposeViewController.canSendText()
    }
    
    // MARK: - WhatsApp Fallback
    
    private func openWhatsApp(to phoneNumber: String, message: String) -> Bool {
        let cleanNumber = phoneNumber.replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "whatsapp://send?phone=\(cleanNumber)&text=\(encodedMessage)"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        
        // Fallback: try to open WhatsApp Web or App Store
        let webUrlString = "https://wa.me/\(cleanNumber)?text=\(encodedMessage)"
        if let webUrl = URL(string: webUrlString) {
            UIApplication.shared.open(webUrl)
            return true
        }
        
        return false
    }
    
    // MARK: - Platform Availability
    
    func getAvailablePlatforms(for phoneNumber: String) -> [MessagePlatform] {
        var available: [MessagePlatform] = [.imessage] // iMessage is always available
        
        // Check if WhatsApp is available
        if let url = URL(string: "whatsapp://"), UIApplication.shared.canOpenURL(url) {
            available.append(.whatsapp)
        }
        
        return available
    }
    
    // MARK: - Emergency Mode Functions
    
    func sendEmergencyMessage(to recipient: MessageRecipient, message: String, platform: MessagePlatform, useScraping: Bool = true) -> Bool {
        guard recipient.isActive && hasUserConsent else { return false }
        
        switch platform {
        case .imessage:
            return sendIMessage(to: recipient.phoneNumber, message: message)
        case .whatsapp:
            return sendWhatsAppMessage(to: recipient, message: message, useScraping: useScraping)
        }
    }
    
    func sendEmergencyMessageToAllRecipients(message: String, platform: MessagePlatform, useScraping: Bool = true) {
        guard hasUserConsent else { return }
        
        let activeRecipients = recipients.filter { $0.isActive && $0.platforms.contains(platform) }
        
        for recipient in activeRecipients {
            _ = sendEmergencyMessage(to: recipient, message: message, platform: platform, useScraping: useScraping)
        }
    }
    
    // MARK: - Default Recipients
    
    private func loadDefaultRecipients() {
        // Charger les destinataires d'urgence par défaut
        let defaultRecipients = [
            MessageRecipient(
                phoneNumber: "17",
                name: "🚔 Police",
                platforms: [.imessage],
                isEmergency: true
            ),
            MessageRecipient(
                phoneNumber: "15",
                name: "🚑 SAMU",
                platforms: [.imessage],
                isEmergency: true
            ),
            MessageRecipient(
                phoneNumber: "18",
                name: "🚒 Pompiers",
                platforms: [.imessage],
                isEmergency: true
            )
        ]
        
        // Ajouter seulement s'ils n'existent pas déjà
        for defaultRecipient in defaultRecipients {
            if !recipients.contains(where: { $0.phoneNumber == defaultRecipient.phoneNumber }) {
                recipients.append(defaultRecipient)
            }
        }
        
        saveRecipients()
    }
    
    // MARK: - Data Persistence
    
    private func saveRecipients() {
        if let data = try? JSONEncoder().encode(recipients) {
            UserDefaults.standard.set(data, forKey: recipientsKey)
        }
    }
    
    private func loadRecipients() {
        if let data = UserDefaults.standard.data(forKey: recipientsKey),
           let loadedRecipients = try? JSONDecoder().decode([MessageRecipient].self, from: data) {
            recipients = loadedRecipients
        }
    }
}

// MARK: - Extensions for Codable support

extension MessagePlatform: Codable {}
extension MessageRecipient: Codable {}

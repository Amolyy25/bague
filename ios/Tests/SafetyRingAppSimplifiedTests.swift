import XCTest
@testable import SafetyRingApp
import Foundation

final class SafetyRingAppSimplifiedTests: XCTestCase {
    
    var multiPlatformManager: MultiPlatformMessageManager!
    var whatsAppScraper: WhatsAppScraperManager!
    var alertSettingsManager: AlertSettingsManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        multiPlatformManager = MultiPlatformMessageManager()
        whatsAppScraper = WhatsAppScraperManager()
        alertSettingsManager = AlertSettingsManager()
    }
    
    override func tearDownWithError() throws {
        multiPlatformManager = nil
        whatsAppScraper = nil
        alertSettingsManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Platform Simplification Tests
    
    func testOnlyTwoPlatformsAvailable() throws {
        // Vérifier qu'il n'y a que 2 plateformes
        let platforms = MessagePlatform.allCases
        XCTAssertEqual(platforms.count, 2, "Il doit y avoir exactement 2 plateformes")
        
        // Vérifier que les plateformes sont iMessage et WhatsApp
        let platformNames = platforms.map { $0.rawValue }
        XCTAssertTrue(platformNames.contains("iMessage"), "iMessage doit être disponible")
        XCTAssertTrue(platformNames.contains("WhatsApp"), "WhatsApp doit être disponible")
        
        // Vérifier qu'il n'y a plus Telegram et Signal
        XCTAssertFalse(platformNames.contains("Telegram"), "Telegram ne doit plus être disponible")
        XCTAssertFalse(platformNames.contains("Signal"), "Signal ne doit plus être disponible")
    }
    
    func testIMessageIsDefault() throws {
        // Vérifier qu'iMessage est la plateforme par défaut
        XCTAssertEqual(multiPlatformManager.selectedPlatform, .imessage, "iMessage doit être la plateforme par défaut")
        
        // Vérifier que les paramètres par défaut pointent vers iMessage
        XCTAssertEqual(alertSettingsManager.settings.preferredPlatform, .imessage, "La plateforme préférée doit être iMessage")
    }
    
    func testPlatformProperties() throws {
        // Test des propriétés d'iMessage
        let imessage = MessagePlatform.imessage
        XCTAssertEqual(imessage.icon, "message.fill", "L'icône d'iMessage doit être correcte")
        XCTAssertEqual(imessage.color, "blue", "La couleur d'iMessage doit être bleue")
        XCTAssertEqual(imessage.displayName, "iMessage (SMS)", "Le nom d'affichage d'iMessage doit être correct")
        
        // Test des propriétés de WhatsApp
        let whatsapp = MessagePlatform.whatsapp
        XCTAssertEqual(whatsapp.icon, "message.circle.fill", "L'icône de WhatsApp doit être correcte")
        XCTAssertEqual(whatsapp.color, "green", "La couleur de WhatsApp doit être verte")
        XCTAssertEqual(whatsapp.displayName, "WhatsApp", "Le nom d'affichage de WhatsApp doit être correct")
    }
    
    // MARK: - Consent System Tests
    
    func testInitialConsentState() throws {
        // Vérifier que l'utilisateur n'a pas donné son consentement au début
        XCTAssertFalse(multiPlatformManager.hasUserConsent, "L'utilisateur ne doit pas avoir donné son consentement au début")
    }
    
    func testConsentFlow() throws {
        // Simuler l'acceptation du consentement
        multiPlatformManager.setUserConsent(true)
        
        // Vérifier que le consentement est enregistré
        XCTAssertTrue(multiPlatformManager.hasUserConsent, "Le consentement doit être enregistré")
        
        // Vérifier que les destinataires par défaut sont chargés
        XCTAssertFalse(multiPlatformManager.recipients.isEmpty, "Les destinataires par défaut doivent être chargés")
        
        // Vérifier qu'il y a les numéros d'urgence
        let emergencyNumbers = multiPlatformManager.recipients.filter { $0.isEmergency }
        XCTAssertEqual(emergencyNumbers.count, 3, "Il doit y avoir 3 numéros d'urgence")
        
        let phoneNumbers = emergencyNumbers.map { $0.phoneNumber }
        XCTAssertTrue(phoneNumbers.contains("17"), "Le numéro de police doit être présent")
        XCTAssertTrue(phoneNumbers.contains("15"), "Le numéro du SAMU doit être présent")
        XCTAssertTrue(phoneNumbers.contains("18"), "Le numéro des pompiers doit être présent")
    }
    
    func testConsentPersistence() throws {
        // Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // Créer un nouveau gestionnaire (simule un redémarrage)
        let newManager = MultiPlatformMessageManager()
        
        // Vérifier que le consentement est persistant
        XCTAssertTrue(newManager.hasUserConsent, "Le consentement doit être persistant")
    }
    
    // MARK: - Message Sending Tests
    
    func testMessageSendingWithoutConsent() throws {
        // Créer un destinataire de test
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test",
            platforms: [.imessage]
        )
        
        // Essayer d'envoyer un message sans consentement
        let result = multiPlatformManager.sendMessage(
            to: recipient,
            message: "Test",
            platform: .imessage
        )
        
        // Le message ne doit pas être envoyé
        XCTAssertFalse(result, "Le message ne doit pas être envoyé sans consentement")
    }
    
    func testMessageSendingWithConsent() throws {
        // Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // Créer un destinataire de test
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test",
            platforms: [.imessage]
        )
        
        // Essayer d'envoyer un message avec consentement
        let result = multiPlatformManager.sendMessage(
            to: recipient,
            message: "Test",
            platform: .imessage
        )
        
        // Le message doit pouvoir être envoyé
        XCTAssertTrue(result, "Le message doit pouvoir être envoyé avec consentement")
    }
    
    // MARK: - WhatsApp Scraping Tests
    
    func testWhatsAppScrapingDisabledByDefault() throws {
        // Vérifier que le scraping WhatsApp est désactivé par défaut
        XCTAssertFalse(whatsAppScraper.isScrapingEnabled, "Le scraping WhatsApp doit être désactivé par défaut")
    }
    
    func testWhatsAppScrapingToggle() throws {
        // Activer le scraping
        whatsAppScraper.enableScraping()
        XCTAssertTrue(whatsAppScraper.isScrapingEnabled, "Le scraping WhatsApp doit être activé")
        
        // Désactiver le scraping
        whatsAppScraper.disableScraping()
        XCTAssertFalse(whatsAppScraper.isScrapingEnabled, "Le scraping WhatsApp doit être désactivé")
    }
    
    func testWhatsAppWarnings() throws {
        // Vérifier qu'il y a des avertissements par défaut
        XCTAssertFalse(whatsAppScraper.warnings.isEmpty, "Il doit y avoir des avertissements par défaut")
        
        // Vérifier qu'il y a des avertissements critiques
        let criticalWarnings = whatsAppScraper.warnings.filter { $0.severity == .critical }
        XCTAssertFalse(criticalWarnings.isEmpty, "Il doit y avoir des avertissements critiques")
        
        // Vérifier qu'il y a des avertissements sur le bannissement
        let bannissementWarnings = whatsAppScraper.warnings.filter { $0.text.contains("bannissement") }
        XCTAssertFalse(bannissementWarnings.isEmpty, "Il doit y avoir des avertissements sur le bannissement")
    }
    
    func testWhatsAppUsageTracking() throws {
        // Vérifier l'état initial
        XCTAssertEqual(whatsAppScraper.usageCount, 0, "Le compteur d'utilisation doit être à 0")
        XCTAssertNil(whatsAppScraper.lastUsed, "La dernière utilisation doit être nil")
        
        // Incrémenter l'utilisation
        whatsAppScraper.incrementUsage()
        XCTAssertEqual(whatsAppScraper.usageCount, 1, "Le compteur d'utilisation doit être à 1")
        XCTAssertNotNil(whatsAppScraper.lastUsed, "La dernière utilisation ne doit pas être nil")
    }
    
    func testWhatsAppRiskAssessment() throws {
        // Test avec utilisation normale
        XCTAssertEqual(whatsAppScraper.getRiskLevel(), "Minimal", "Le niveau de risque doit être minimal")
        
        // Simuler une utilisation élevée
        for _ in 0..<15 {
            whatsAppScraper.incrementUsage()
        }
        
        XCTAssertEqual(whatsAppScraper.getRiskLevel(), "Élevé", "Le niveau de risque doit être élevé")
    }
    
    // MARK: - Emergency Message Tests
    
    func testEmergencyMessageSending() throws {
        // Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // Créer un destinataire d'urgence
        let emergencyRecipient = MessageRecipient(
            phoneNumber: "17",
            name: "Police",
            platforms: [.imessage],
            isEmergency: true
        )
        
        // Ajouter le destinataire
        multiPlatformManager.addRecipient(emergencyRecipient)
        
        // Envoyer un message d'urgence
        let result = multiPlatformManager.sendEmergencyMessage(
            to: emergencyRecipient,
            message: "🚨 URGENCE - Test",
            platform: .imessage,
            useScraping: false
        )
        
        XCTAssertTrue(result, "Le message d'urgence doit pouvoir être envoyé")
    }
    
    func testEmergencyMessageToAllRecipients() throws {
        // Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // Créer plusieurs destinataires
        let recipient1 = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test 1",
            platforms: [.imessage]
        )
        let recipient2 = MessageRecipient(
            phoneNumber: "+33987654321",
            name: "Test 2",
            platforms: [.whatsapp]
        )
        
        // Ajouter les destinataires
        multiPlatformManager.addRecipient(recipient1)
        multiPlatformManager.addRecipient(recipient2)
        
        // Envoyer un message d'urgence à tous
        multiPlatformManager.sendEmergencyMessageToAllRecipients(
            message: "🚨 URGENCE - Test global",
            platform: .imessage,
            useScraping: false
        )
        
        // Vérifier que les destinataires sont présents
        XCTAssertEqual(multiPlatformManager.recipients.count, 5, "Il doit y avoir 5 destinataires (3 par défaut + 2 ajoutés)")
    }
    
    // MARK: - Settings Tests
    
    func testDefaultSettings() throws {
        // Vérifier les paramètres par défaut
        XCTAssertTrue(alertSettingsManager.settings.enableVibration, "Les vibrations doivent être activées par défaut")
        XCTAssertTrue(alertSettingsManager.settings.enableSound, "Le son doit être activé par défaut")
        XCTAssertTrue(alertSettingsManager.settings.enableSpeech, "La parole doit être activée par défaut")
        XCTAssertEqual(alertSettingsManager.settings.vibrationDuration, 5.0, "La durée de vibration doit être de 5 secondes")
        XCTAssertEqual(alertSettingsManager.settings.preferredPlatform, .imessage, "La plateforme préférée doit être iMessage")
    }
    
    func testSettingsValidation() throws {
        // Tester la validation des paramètres
        let errors = alertSettingsManager.validateSettings()
        XCTAssertTrue(errors.isEmpty, "Il ne doit pas y avoir d'erreurs de validation avec les paramètres par défaut")
        
        // Tester avec des valeurs invalides
        alertSettingsManager.setVibrationDuration(15.0) // Valeur trop élevée
        alertSettingsManager.setAlertVolume(1.5) // Volume trop élevé
        
        let newErrors = alertSettingsManager.validateSettings()
        XCTAssertFalse(newErrors.isEmpty, "Il doit y avoir des erreurs de validation avec des valeurs invalides")
    }
    
    func testPlatformSpecificSettings() throws {
        // Tester les paramètres spécifiques à iMessage
        let imessageSettings = alertSettingsManager.getPlatformSettings(for: .imessage)
        XCTAssertEqual(imessageSettings["name"] as? String, "iMessage (SMS)", "Le nom d'iMessage doit être correct")
        XCTAssertTrue(imessageSettings["isAlwaysAvailable"] as? Bool == true, "iMessage doit toujours être disponible")
        XCTAssertFalse(imessageSettings["requiresConsent"] as? Bool == true, "iMessage ne doit pas nécessiter de consentement")
        
        // Tester les paramètres spécifiques à WhatsApp
        let whatsappSettings = alertSettingsManager.getPlatformSettings(for: .whatsapp)
        XCTAssertEqual(whatsappSettings["name"] as? String, "WhatsApp", "Le nom de WhatsApp doit être correct")
        XCTAssertFalse(whatsappSettings["isAlwaysAvailable"] as? Bool == true, "WhatsApp ne doit pas toujours être disponible")
        XCTAssertTrue(whatsappSettings["requiresConsent"] as? Bool == true, "WhatsApp doit nécessiter un consentement")
    }
    
    // MARK: - Data Persistence Tests
    
    func testSettingsPersistence() throws {
        // Modifier les paramètres
        alertSettingsManager.setVibrationDuration(7.0)
        alertSettingsManager.setAlertVolume(0.9)
        
        // Créer un nouveau gestionnaire (simule un redémarrage)
        let newSettingsManager = AlertSettingsManager()
        
        // Vérifier que les paramètres sont persistants
        XCTAssertEqual(newSettingsManager.settings.vibrationDuration, 7.0, "La durée de vibration doit être persistante")
        XCTAssertEqual(newSettingsManager.settings.alertVolume, 0.9, "Le volume d'alerte doit être persistant")
    }
    
    func testRecipientsPersistence() throws {
        // Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // Ajouter un destinataire personnalisé
        let customRecipient = MessageRecipient(
            phoneNumber: "+33111222333",
            name: "Contact Personnalisé",
            platforms: [.imessage, .whatsapp]
        )
        multiPlatformManager.addRecipient(customRecipient)
        
        // Créer un nouveau gestionnaire (simule un redémarrage)
        let newManager = MultiPlatformMessageManager()
        
        // Vérifier que les destinataires sont persistants
        let savedRecipient = newManager.recipients.first { $0.phoneNumber == "+33111222333" }
        XCTAssertNotNil(savedRecipient, "Le destinataire personnalisé doit être persistant")
        XCTAssertEqual(savedRecipient?.name, "Contact Personnalisé", "Le nom du destinataire doit être persistant")
        XCTAssertEqual(savedRecipient?.platforms.count, 2, "Les plateformes du destinataire doivent être persistantes")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteEmergencyFlow() throws {
        // 1. Donner le consentement
        multiPlatformManager.setUserConsent(true)
        
        // 2. Vérifier que les destinataires d'urgence sont chargés
        let emergencyRecipients = multiPlatformManager.recipients.filter { $0.isEmergency }
        XCTAssertEqual(emergencyRecipients.count, 3, "Les 3 destinataires d'urgence doivent être chargés")
        
        // 3. Vérifier que tous les destinataires d'urgence utilisent iMessage
        for recipient in emergencyRecipients {
            XCTAssertTrue(recipient.platforms.contains(.imessage), "Tous les destinataires d'urgence doivent supporter iMessage")
        }
        
        // 4. Vérifier que l'application peut envoyer des messages
        let testRecipient = emergencyRecipients.first!
        let result = multiPlatformManager.sendEmergencyMessage(
            to: testRecipient,
            message: "🚨 TEST URGENCE",
            platform: .imessage,
            useScraping: false
        )
        
        XCTAssertTrue(result, "L'envoi de message d'urgence doit fonctionner")
    }
    
    func testWhatsAppIntegration() throws {
        // 1. Activer le scraping WhatsApp
        whatsAppScraper.enableScraping()
        
        // 2. Vérifier que l'utilisateur a vu l'avertissement
        XCTAssertTrue(whatsAppScraper.hasSeenRecentWarning(), "L'utilisateur doit avoir vu l'avertissement récemment")
        
        // 3. Tester l'envoi de message WhatsApp
        let result = await whatsAppScraper.sendMessage(
            to: "+33123456789",
            message: "Test WhatsApp"
        )
        
        XCTAssertTrue(result, "L'envoi de message WhatsApp doit fonctionner")
        
        // 4. Vérifier que l'utilisation est comptabilisée
        XCTAssertEqual(whatsAppScraper.usageCount, 1, "L'utilisation doit être comptabilisée")
    }
}

// MARK: - Test Helpers

extension SafetyRingAppSimplifiedTests {
    func createTestRecipient(phoneNumber: String, platforms: [MessagePlatform]) -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: phoneNumber,
            name: "Test \(phoneNumber)",
            platforms: platforms
        )
    }
    
    func createEmergencyRecipient(phoneNumber: String) -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: phoneNumber,
            name: "🚨 \(phoneNumber)",
            platforms: [.imessage],
            isEmergency: true
        )
    }
}

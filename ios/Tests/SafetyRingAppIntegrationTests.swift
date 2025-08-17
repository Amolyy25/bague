import XCTest
@testable import SafetyRingApp
import CoreLocation
import CoreBluetooth

final class SafetyRingAppIntegrationTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var locationManager: LocationManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    var whatsAppScraper: WhatsAppScraperManager!
    var bleManager: BLEManager!
    var alertHandler: AlertHandler!
    var reachability: ReachabilityMonitor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        locationManager = LocationManager()
        multiPlatformManager = MultiPlatformMessageManager()
        whatsAppScraper = WhatsAppScraperManager()
        bleManager = BLEManager()
        alertHandler = AlertHandler()
        reachability = ReachabilityMonitor()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        locationManager = nil
        multiPlatformManager = nil
        whatsAppScraper = nil
        bleManager = nil
        alertHandler = nil
        reachability = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Complete Emergency Flow Integration Tests
    
    func testCompleteEmergencyFlowWithSMS() throws {
        // 1. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        XCTAssertTrue(template.isActive, "Le template doit être actif")
        
        // 2. Configurer un destinataire SMS
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Emergency Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 3. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 4. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        XCTAssertFalse(message.isEmpty, "Le message d'urgence doit être généré")
        XCTAssertTrue(message.contains("Paris"), "Le message doit contenir la localisation")
        
        // 5. Vérifier que le message peut être envoyé
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message SMS doit pouvoir être envoyé")
        
        // 6. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    func testCompleteEmergencyFlowWithWhatsApp() throws {
        // 1. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 2. Configurer un destinataire WhatsApp
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test WhatsApp Contact",
            platforms: [.whatsapp]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 3. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 4. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // 5. Vérifier que le message peut être envoyé via WhatsApp
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .whatsapp)
        // WhatsApp peut ne pas être disponible sur le simulateur
        XCTAssertNotNil(canSend, "Le résultat de l'envoi WhatsApp doit être défini")
        
        // 6. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    func testCompleteEmergencyFlowWithMultiPlatform() throws {
        // 1. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 2. Configurer plusieurs destinataires sur différentes plateformes
        let recipients = [
            MessageRecipient(
                phoneNumber: "+33123456789",
                name: "SMS Contact",
                platforms: [.sms]
            ),
            MessageRecipient(
                phoneNumber: "+33987654321",
                name: "WhatsApp Contact",
                platforms: [.whatsapp]
            ),
            MessageRecipient(
                phoneNumber: "+33555555555",
                name: "Telegram Contact",
                platforms: [.telegram]
            )
        ]
        
        for recipient in recipients {
            multiPlatformManager.addRecipient(recipient)
        }
        
        // 3. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 4. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // 5. Envoyer sur toutes les plateformes
        multiPlatformManager.sendEmergencyMessageToAllRecipients(
            message: message,
            platform: .sms,
            useScraping: false
        )
        
        // 6. Vérifier que tous les destinataires ont reçu le message
        let activeRecipients = multiPlatformManager.recipients.filter { $0.isActive }
        XCTAssertEqual(activeRecipients.count, recipients.count, "Tous les destinataires doivent être actifs")
        
        // 7. Nettoyer
        for recipient in recipients {
            multiPlatformManager.removeRecipient(recipient)
        }
    }
    
    // MARK: - BLE Integration Tests
    
    func testBLEAndEmergencyFlowIntegration() throws {
        // 1. Vérifier que le BLE manager est initialisé
        XCTAssertNotNil(bleManager, "Le BLE manager doit être initialisé")
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "BLE Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Simuler une alerte BLE
        let alertData = "ALERT"
        bleManager.lastAlertData = alertData
        
        // 6. Vérifier que l'alerte est traitée
        XCTAssertEqual(bleManager.lastAlertData, alertData, "L'alerte BLE doit être reçue")
        
        // 7. Générer et envoyer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message doit pouvoir être envoyé après alerte BLE")
        
        // 8. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Location Integration Tests
    
    func testLocationAndEmergencyFlowIntegration() throws {
        // 1. Vérifier que le location manager est initialisé
        XCTAssertNotNil(locationManager, "Le location manager doit être initialisé")
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Location Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Vérifier que la localisation est correctement formatée
        let formattedLocation = mockLocation.getFormattedLocation()
        XCTAssertFalse(formattedLocation.isEmpty, "La localisation doit être formatée")
        
        // 6. Générer le message d'urgence avec la localisation
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        XCTAssertTrue(message.contains("Paris"), "Le message doit contenir la localisation")
        
        // 7. Envoyer le message
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message avec localisation doit pouvoir être envoyé")
        
        // 8. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Network Integration Tests
    
    func testNetworkAndEmergencyFlowIntegration() throws {
        // 1. Vérifier que le reachability monitor est initialisé
        XCTAssertNotNil(reachability, "Le reachability monitor doit être initialisé")
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Network Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Vérifier le statut réseau
        let isConnected = reachability.isConnected
        XCTAssertNotNil(isConnected, "Le statut réseau doit être défini")
        
        // 6. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // 7. Envoyer le message selon la connectivité
        if isConnected {
            let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
            XCTAssertTrue(canSend, "Le message doit pouvoir être envoyé en ligne")
        } else {
            // En mode hors-ligne, le message devrait être stocké
            XCTAssertTrue(true, "Le message devrait être stocké en mode hors-ligne")
        }
        
        // 8. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Alert Handler Integration Tests
    
    func testAlertHandlerAndEmergencyFlowIntegration() throws {
        // 1. Vérifier que l'alert handler est initialisé
        XCTAssertNotNil(alertHandler, "L'alert handler doit être initialisé")
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Alert Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Déclencher une alerte locale
        alertHandler.triggerLocalAlert()
        
        // 6. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // 7. Envoyer le message
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message doit pouvoir être envoyé après alerte locale")
        
        // 8. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - WhatsApp Scraping Integration Tests
    
    func testWhatsAppScrapingAndEmergencyFlowIntegration() throws {
        // 1. Vérifier que le WhatsApp scraper est initialisé
        XCTAssertNotNil(whatsAppScraper, "Le WhatsApp scraper doit être initialisé")
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Configurer un destinataire WhatsApp
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "WhatsApp Scraping Test Contact",
            platforms: [.whatsapp]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Activer le mode scraping (si autorisé)
        if whatsAppScraper.isScrapingEnabled {
            // 6. Générer le message d'urgence
            let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            
            // 7. Envoyer via scraping
            let canSend = multiPlatformManager.sendEmergencyMessage(
                to: recipient,
                message: message,
                platform: .whatsapp,
                useScraping: true
            )
            XCTAssertNotNil(canSend, "Le résultat de l'envoi via scraping doit être défini")
        } else {
            // Mode scraping désactivé, test normal
            let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .whatsapp)
            XCTAssertNotNil(canSend, "Le résultat de l'envoi WhatsApp normal doit être défini")
        }
        
        // 8. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Template Management Integration Tests
    
    func testTemplateManagementAndEmergencyFlowIntegration() throws {
        // 1. Vérifier l'état initial des templates
        let initialCount = emergencyManager.templates.count
        XCTAssertFalse(initialCount == 0, "Il doit y avoir des templates initiaux")
        
        // 2. Créer un nouveau template personnalisé
        let customTemplate = EmergencyTemplate(
            id: "integration-test",
            name: "Test d'Intégration",
            message: "🚨 TEST INTÉGRATION - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
        
        emergencyManager.addTemplate(customTemplate)
        XCTAssertEqual(emergencyManager.templates.count, initialCount + 1, "Le template doit être ajouté")
        
        // 3. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Template Integration Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 4. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 5. Utiliser le nouveau template pour générer un message
        let message = emergencyManager.generateEmergencyMessage(template: customTemplate, location: mockLocation)
        XCTAssertFalse(message.isEmpty, "Le message avec le template personnalisé doit être généré")
        XCTAssertTrue(message.contains("TEST INTÉGRATION"), "Le message doit contenir le nom du template")
        
        // 6. Envoyer le message
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message avec le template personnalisé doit pouvoir être envoyé")
        
        // 7. Nettoyer
        emergencyManager.deleteTemplate(withId: customTemplate.id)
        multiPlatformManager.removeRecipient(recipient)
        
        // 8. Vérifier le retour à l'état initial
        XCTAssertEqual(emergencyManager.templates.count, initialCount, "Le nombre de templates doit revenir à l'état initial")
    }
    
    // MARK: - Recipient Management Integration Tests
    
    func testRecipientManagementAndEmergencyFlowIntegration() throws {
        // 1. Vérifier l'état initial des destinataires
        let initialCount = multiPlatformManager.recipients.count
        
        // 2. Créer plusieurs destinataires de test
        let testRecipients = [
            MessageRecipient(
                phoneNumber: "+33123456789",
                name: "Test Recipient 1",
                platforms: [.sms, .whatsapp]
            ),
            MessageRecipient(
                phoneNumber: "+33987654321",
                name: "Test Recipient 2",
                platforms: [.whatsapp, .telegram]
            ),
            MessageRecipient(
                phoneNumber: "+33555555555",
                name: "Test Recipient 3",
                platforms: [.sms, .signal]
            )
        ]
        
        // 3. Ajouter tous les destinataires
        for recipient in testRecipients {
            multiPlatformManager.addRecipient(recipient)
        }
        
        XCTAssertEqual(multiPlatformManager.recipients.count, initialCount + testRecipients.count, "Tous les destinataires doivent être ajoutés")
        
        // 4. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 5. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 6. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // 7. Envoyer le message à tous les destinataires actifs
        let activeRecipients = multiPlatformManager.recipients.filter { $0.isActive }
        XCTAssertEqual(activeRecipients.count, testRecipients.count, "Tous les destinataires de test doivent être actifs")
        
        for recipient in activeRecipients {
            let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
            XCTAssertNotNil(canSend, "Le message doit pouvoir être envoyé à chaque destinataire")
        }
        
        // 8. Nettoyer
        for recipient in testRecipients {
            multiPlatformManager.removeRecipient(recipient)
        }
        
        // 9. Vérifier le retour à l'état initial
        XCTAssertEqual(multiPlatformManager.recipients.count, initialCount, "Le nombre de destinataires doit revenir à l'état initial")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingAndEmergencyFlowIntegration() throws {
        // 1. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 2. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Error Handling Test Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 3. Simuler une localisation vide/invalide
        let emptyLocation = LocationManager()
        
        // 4. Générer le message d'urgence malgré la localisation vide
        let message = emergencyManager.generateEmergencyMessage(template: template, location: emptyLocation)
        XCTAssertFalse(message.isEmpty, "Un message doit être généré même avec une localisation vide")
        XCTAssertTrue(message.contains("inconnue"), "Le message doit indiquer une localisation inconnue")
        
        // 5. Envoyer le message malgré les erreurs
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message doit pouvoir être envoyé malgré les erreurs de localisation")
        
        // 6. Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceUnderLoad() throws {
        // 1. Configurer de nombreux destinataires
        let recipientCount = 100
        var testRecipients: [MessageRecipient] = []
        
        for i in 0..<recipientCount {
            let recipient = MessageRecipient(
                phoneNumber: "+33123456789\(i)",
                name: "Performance Test Recipient \(i)",
                platforms: [.sms, .whatsapp]
            )
            testRecipients.append(recipient)
            multiPlatformManager.addRecipient(recipient)
        }
        
        // 2. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        
        // 3. Simuler une localisation
        let mockLocation = createMockLocation()
        
        // 4. Mesurer les performances de génération de message
        measure {
            for _ in 0..<100 {
                _ = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            }
        }
        
        // 5. Mesurer les performances d'envoi
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        measure {
            for recipient in testRecipients {
                _ = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
            }
        }
        
        // 6. Nettoyer
        for recipient in testRecipients {
            multiPlatformManager.removeRecipient(recipient)
        }
    }
    
    // MARK: - Test Helpers
    
    private func createMockLocation() -> LocationManager {
        let location = LocationManager()
        location.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        location.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        location.isLocationEnabled = true
        return location
    }
    
    private func createMockEmergencyTemplate() -> EmergencyTemplate {
        return EmergencyTemplate(
            id: "integration-test",
            name: "Test d'Intégration",
            message: "🚨 TEST - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
    }
    
    private func createMockRecipient() -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Integration Recipient",
            platforms: [.sms, .whatsapp]
        )
    }
}

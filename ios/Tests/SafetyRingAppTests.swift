import XCTest
@testable import SafetyRingApp

final class SafetyRingAppTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var locationManager: LocationManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        locationManager = LocationManager()
        multiPlatformManager = MultiPlatformMessageManager()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        locationManager = nil
        multiPlatformManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Emergency Message Manager Tests
    
    func testEmergencyTemplatesInitialization() throws {
        XCTAssertFalse(emergencyManager.templates.isEmpty, "Les templates d'urgence doivent être initialisés")
        
        let activeTemplates = emergencyManager.templates.filter { $0.isActive }
        XCTAssertFalse(activeTemplates.isEmpty, "Au moins un template doit être actif")
        
        // Vérifier que les templates ont des noms et messages valides
        for template in emergencyManager.templates {
            XCTAssertFalse(template.name.isEmpty, "Le nom du template ne doit pas être vide")
            XCTAssertFalse(template.message.isEmpty, "Le message du template ne doit pas être vide")
            XCTAssertFalse(template.id.isEmpty, "L'ID du template ne doit pas être vide")
        }
    }
    
    func testEmergencyMessageGeneration() throws {
        // Simuler une localisation
        let mockLocation = LocationManager()
        mockLocation.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        mockLocation.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        
        let template = emergencyManager.templates.first!
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        XCTAssertFalse(message.isEmpty, "Le message généré ne doit pas être vide")
        XCTAssertTrue(message.contains("Paris"), "Le message doit contenir l'adresse")
        XCTAssertTrue(message.contains("48.8566"), "Le message doit contenir la latitude")
        XCTAssertTrue(message.contains("2.3522"), "Le message doit contenir la longitude")
    }
    
    func testCustomMessageGeneration() throws {
        let mockLocation = LocationManager()
        mockLocation.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        mockLocation.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        
        let message = emergencyManager.generateCustomMessage(location: mockLocation)
        
        XCTAssertFalse(message.isEmpty, "Le message personnalisé ne doit pas être vide")
        XCTAssertTrue(message.contains("Paris"), "Le message doit contenir l'adresse")
    }
    
    func testTemplateManagement() throws {
        let initialCount = emergencyManager.templates.count
        
        // Ajouter un nouveau template
        let newTemplate = EmergencyTemplate(
            id: "test",
            name: "Test Template",
            message: "Test message",
            isActive: true,
            category: .custom
        )
        
        emergencyManager.addTemplate(newTemplate)
        XCTAssertEqual(emergencyManager.templates.count, initialCount + 1, "Le template doit être ajouté")
        
        // Modifier le template
        let updatedTemplate = EmergencyTemplate(
            id: "test",
            name: "Updated Test Template",
            message: "Updated test message",
            isActive: true,
            category: .custom
        )
        
        emergencyManager.updateTemplate(updatedTemplate)
        let updated = emergencyManager.templates.first { $0.id == "test" }
        XCTAssertEqual(updated?.name, "Updated Test Template", "Le template doit être mis à jour")
        
        // Supprimer le template
        emergencyManager.deleteTemplate(withId: "test")
        XCTAssertEqual(emergencyManager.templates.count, initialCount, "Le template doit être supprimé")
    }
    
    // MARK: - Location Manager Tests
    
    func testLocationManagerInitialization() throws {
        XCTAssertNotNil(locationManager, "Le LocationManager doit être initialisé")
        XCTAssertEqual(locationManager.lastAddress, "Localisation inconnue", "L'adresse par défaut doit être définie")
    }
    
    func testLocationFormattedOutput() throws {
        // Simuler des coordonnées
        locationManager.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        locationManager.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        
        let formattedLocation = locationManager.getFormattedLocation()
        XCTAssertFalse(formattedLocation.isEmpty, "La localisation formatée ne doit pas être vide")
        XCTAssertTrue(formattedLocation.contains("Paris"), "La localisation doit contenir la ville")
        
        let emergencyText = locationManager.getEmergencyLocationText()
        XCTAssertFalse(emergencyText.isEmpty, "Le texte d'urgence ne doit pas être vide")
        XCTAssertTrue(emergencyText.contains("Paris"), "Le texte d'urgence doit contenir la ville")
    }
    
    // MARK: - Multi-Platform Message Manager Tests
    
    func testRecipientManagement() throws {
        let initialCount = multiPlatformManager.recipients.count
        
        // Ajouter un destinataire
        let newRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Contact",
            platforms: [.sms, .whatsapp]
        )
        
        multiPlatformManager.addRecipient(newRecipient)
        XCTAssertEqual(multiPlatformManager.recipients.count, initialCount + 1, "Le destinataire doit être ajouté")
        
        // Modifier le destinataire
        let updatedRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Updated Test Contact",
            platforms: [.sms, .whatsapp, .telegram]
        )
        
        multiPlatformManager.updateRecipient(updatedRecipient)
        let updated = multiPlatformManager.recipients.first { $0.phoneNumber == "+33123456789" }
        XCTAssertEqual(updated?.name, "Updated Test Contact", "Le destinataire doit être mis à jour")
        XCTAssertEqual(updated?.platforms.count, 3, "Les plateformes doivent être mises à jour")
        
        // Supprimer le destinataire
        multiPlatformManager.removeRecipient(updatedRecipient)
        XCTAssertEqual(multiPlatformManager.recipients.count, initialCount, "Le destinataire doit être supprimé")
    }
    
    func testPlatformAvailability() throws {
        let availablePlatforms = multiPlatformManager.getAvailablePlatforms(for: "+33123456789")
        
        // SMS est toujours disponible
        XCTAssertTrue(availablePlatforms.contains(.sms), "SMS doit toujours être disponible")
        
        // Les autres plateformes dépendent des applications installées
        XCTAssertNotNil(availablePlatforms, "Les plateformes disponibles doivent être retournées")
    }
    
    // MARK: - Performance Tests
    
    func testEmergencyMessageGenerationPerformance() throws {
        let mockLocation = LocationManager()
        mockLocation.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        mockLocation.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        
        measure {
            for _ in 0..<100 {
                _ = emergencyManager.generateCustomMessage(location: mockLocation)
            }
        }
    }
    
    func testTemplateSearchPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = emergencyManager.templates.filter { $0.isActive }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteEmergencyFlow() throws {
        // 1. Configurer un template d'urgence
        let template = emergencyManager.templates.first!
        XCTAssertTrue(template.isActive, "Le template doit être actif")
        
        // 2. Configurer un destinataire
        let recipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Emergency Contact",
            platforms: [.sms]
        )
        multiPlatformManager.addRecipient(recipient)
        
        // 3. Simuler une localisation
        let mockLocation = LocationManager()
        mockLocation.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        mockLocation.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        
        // 4. Générer le message d'urgence
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        XCTAssertFalse(message.isEmpty, "Le message d'urgence doit être généré")
        
        // 5. Vérifier que le destinataire peut recevoir le message
        let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
        XCTAssertTrue(canSend, "Le message doit pouvoir être envoyé")
        
        // Nettoyer
        multiPlatformManager.removeRecipient(recipient)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidTemplateHandling() throws {
        // Tester avec un template invalide
        let invalidTemplate = EmergencyTemplate(
            id: "",
            name: "",
            message: "",
            isActive: false,
            category: .custom
        )
        
        let mockLocation = LocationManager()
        let message = emergencyManager.generateEmergencyMessage(template: invalidTemplate, location: mockLocation)
        
        // Le message doit être généré même avec un template invalide
        XCTAssertFalse(message.isEmpty, "Un message doit être généré même avec un template invalide")
    }
    
    func testEmptyLocationHandling() throws {
        let template = emergencyManager.templates.first!
        let emptyLocation = LocationManager()
        
        let message = emergencyManager.generateEmergencyMessage(template: template, location: emptyLocation)
        
        // Le message doit être généré même sans localisation
        XCTAssertFalse(message.isEmpty, "Un message doit être généré même sans localisation")
        XCTAssertTrue(message.contains("inconnue"), "Le message doit indiquer une localisation inconnue")
    }
}

// MARK: - Test Helpers

extension SafetyRingAppTests {
    
    func createMockLocation() -> LocationManager {
        let location = LocationManager()
        location.lastCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        location.lastAddress = "1 Rue de la Paix, 75001 Paris, France"
        location.isLocationEnabled = true
        return location
    }
    
    func createMockEmergencyTemplate() -> EmergencyTemplate {
        return EmergencyTemplate(
            id: "test-emergency",
            name: "Test Emergency",
            message: "🚨 TEST - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
    }
    
    func createMockRecipient() -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Recipient",
            platforms: [.sms, .whatsapp]
        )
    }
}

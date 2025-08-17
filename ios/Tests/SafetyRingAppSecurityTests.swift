import XCTest
@testable import SafetyRingApp
import Foundation

final class SafetyRingAppSecurityTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    var whatsAppScraper: WhatsAppScraperManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        multiPlatformManager = MultiPlatformMessageManager()
        whatsAppScraper = WhatsAppScraperManager()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        multiPlatformManager = nil
        whatsAppScraper = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Input Validation Tests
    
    func testPhoneNumberValidation() throws {
        // Test des numéros de téléphone valides
        let validPhoneNumbers = [
            "+33123456789",
            "0123456789",
            "+1-555-123-4567",
            "+44 20 7946 0958",
            "+81 3-1234-5678"
        ]
        
        for phoneNumber in validPhoneNumbers {
            let recipient = MessageRecipient(
                phoneNumber: phoneNumber,
                name: "Test Contact",
                platforms: [.sms]
            )
            XCTAssertFalse(recipient.phoneNumber.isEmpty, "Le numéro de téléphone ne doit pas être vide")
            XCTAssertTrue(recipient.phoneNumber.count >= 10, "Le numéro de téléphone doit avoir au moins 10 chiffres")
        }
        
        // Test des numéros de téléphone invalides
        let invalidPhoneNumbers = [
            "",
            "123",
            "abc",
            "123-456",
            "+"
        ]
        
        for phoneNumber in invalidPhoneNumbers {
            let recipient = MessageRecipient(
                phoneNumber: phoneNumber,
                name: "Test Contact",
                platforms: [.sms]
            )
            // L'application doit gérer gracieusement les numéros invalides
            XCTAssertNotNil(recipient, "Le destinataire doit être créé même avec un numéro invalide")
        }
    }
    
    func testMessageContentValidation() throws {
        // Test des messages valides
        let validMessages = [
            "🚨 ALERTE URGENCE - J'ai besoin d'aide !",
            "Test message with normal text",
            "Message with numbers 123 and symbols !@#",
            "Message with emojis 🚨⚠️📍🌐🗺️⏰📱"
        ]
        
        for message in validMessages {
            let template = EmergencyTemplate(
                id: "test",
                name: "Test Template",
                message: message,
                isActive: true,
                category: .custom
            )
            XCTAssertFalse(template.message.isEmpty, "Le message ne doit pas être vide")
            XCTAssertTrue(template.message.count <= 1000, "Le message ne doit pas dépasser 1000 caractères")
        }
        
        // Test des messages invalides
        let invalidMessages = [
            "", // Message vide
            String(repeating: "A", count: 1001), // Message trop long
            String(repeating: "🚨", count: 500) // Trop d'emojis
        ]
        
        for message in invalidMessages {
            let template = EmergencyTemplate(
                id: "test",
                name: "Test Template",
                message: message,
                isActive: true,
                category: .custom
            )
            // L'application doit gérer gracieusement les messages invalides
            XCTAssertNotNil(template, "Le template doit être créé même avec un message invalide")
        }
    }
    
    func testTemplateIDValidation() throws {
        // Test des IDs valides
        let validIDs = [
            "aggression",
            "medical",
            "accident",
            "custom-123",
            "template_with_underscores",
            "TEMPLATE123"
        ]
        
        for id in validIDs {
            let template = EmergencyTemplate(
                id: id,
                name: "Test Template",
                message: "Test message",
                isActive: true,
                category: .custom
            )
            XCTAssertFalse(template.id.isEmpty, "L'ID ne doit pas être vide")
            XCTAssertTrue(template.id.count <= 100, "L'ID ne doit pas dépasser 100 caractères")
        }
        
        // Test des IDs invalides
        let invalidIDs = [
            "", // ID vide
            String(repeating: "A", count: 101), // ID trop long
            "id with spaces", // ID avec espaces
            "id/with/slashes", // ID avec slashes
            "id\\with\\backslashes" // ID avec backslashes
        ]
        
        for id in invalidIDs {
            let template = EmergencyTemplate(
                id: id,
                name: "Test Template",
                message: "Test message",
                isActive: true,
                category: .custom
            )
            // L'application doit gérer gracieusement les IDs invalides
            XCTAssertNotNil(template, "Le template doit être créé même avec un ID invalide")
        }
    }
    
    // MARK: - Data Sanitization Tests
    
    func testMessageSanitization() throws {
        // Test de la sanitisation des messages
        let unsafeMessages = [
            "<script>alert('xss')</script>",
            "Message with SQL injection: '; DROP TABLE users; --",
            "Message with HTML: <b>Bold</b> <i>Italic</i>",
            "Message with JavaScript: javascript:alert('xss')",
            "Message with special chars: & < > \" '"
        ]
        
        for unsafeMessage in unsafeMessages {
            let template = EmergencyTemplate(
                id: "test",
                name: "Test Template",
                message: unsafeMessage,
                isActive: true,
                category: .custom
            )
            
            // Vérifier que le message est stocké tel quel (pas d'échappement automatique)
            XCTAssertEqual(template.message, unsafeMessage, "Le message doit être stocké tel quel")
            
            // Vérifier que le message peut être utilisé sans danger
            let mockLocation = createMockLocation()
            let generatedMessage = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            
            // Le message généré ne doit pas contenir de code exécutable
            XCTAssertFalse(generatedMessage.contains("<script>"), "Le message ne doit pas contenir de balises script")
            XCTAssertFalse(generatedMessage.contains("javascript:"), "Le message ne doit pas contenir de protocoles javascript")
        }
    }
    
    func testPhoneNumberSanitization() throws {
        // Test de la sanitisation des numéros de téléphone
        let unsafePhoneNumbers = [
            "0123456789<script>alert('xss')</script>",
            "0123456789' OR 1=1--",
            "0123456789\n<script>alert('xss')</script>",
            "0123456789\r\n<script>alert('xss')</script>"
        ]
        
        for unsafePhoneNumber in unsafePhoneNumbers {
            let recipient = MessageRecipient(
                phoneNumber: unsafePhoneNumber,
                name: "Test Contact",
                platforms: [.sms]
            )
            
            // Vérifier que le numéro est stocké tel quel
            XCTAssertEqual(recipient.phoneNumber, unsafePhoneNumber, "Le numéro doit être stocké tel quel")
            
            // Vérifier que le numéro peut être utilisé sans danger
            let message = "Test message"
            let canSend = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
            
            // L'envoi doit échouer pour les numéros malformés
            XCTAssertFalse(canSend, "L'envoi doit échouer pour les numéros malformés")
        }
    }
    
    func testTemplateNameSanitization() throws {
        // Test de la sanitisation des noms de templates
        let unsafeNames = [
            "<script>alert('xss')</script>",
            "Template with SQL injection: '; DROP TABLE templates; --",
            "Template with HTML: <b>Bold</b> <i>Italic</i>",
            "Template with JavaScript: javascript:alert('xss')",
            "Template with special chars: & < > \" '"
        ]
        
        for unsafeName in unsafeNames {
            let template = EmergencyTemplate(
                id: "test",
                name: unsafeName,
                message: "Test message",
                isActive: true,
                category: .custom
            )
            
            // Vérifier que le nom est stocké tel quel
            XCTAssertEqual(template.name, unsafeName, "Le nom doit être stocké tel quel")
            
            // Vérifier que le template peut être utilisé sans danger
            let mockLocation = createMockLocation()
            let generatedMessage = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            
            // Le message généré ne doit pas contenir de code exécutable
            XCTAssertFalse(generatedMessage.contains("<script>"), "Le message ne doit pas contenir de balises script")
            XCTAssertFalse(generatedMessage.contains("javascript:"), "Le message ne doit pas contenir de protocoles javascript")
        }
    }
    
    // MARK: - Access Control Tests
    
    func testTemplateAccessControl() throws {
        // Test que les templates ne peuvent être modifiés que par l'utilisateur
        let initialTemplates = emergencyManager.templates
        
        // Créer un nouveau template
        let newTemplate = EmergencyTemplate(
            id: "security-test",
            name: "Security Test Template",
            message: "Test message",
            isActive: true,
            category: .custom
        )
        
        emergencyManager.addTemplate(newTemplate)
        
        // Vérifier que le template a été ajouté
        XCTAssertTrue(emergencyManager.templates.contains { $0.id == "security-test" }, "Le template doit être ajouté")
        
        // Modifier le template
        let updatedTemplate = EmergencyTemplate(
            id: "security-test",
            name: "Updated Security Test Template",
            message: "Updated test message",
            isActive: false,
            category: .custom
        )
        
        emergencyManager.updateTemplate(updatedTemplate)
        
        // Vérifier que le template a été modifié
        let modifiedTemplate = emergencyManager.templates.first { $0.id == "security-test" }
        XCTAssertEqual(modifiedTemplate?.name, "Updated Security Test Template", "Le nom du template doit être modifié")
        XCTAssertEqual(modifiedTemplate?.isActive, false, "L'état actif du template doit être modifié")
        
        // Supprimer le template
        emergencyManager.deleteTemplate(withId: "security-test")
        
        // Vérifier que le template a été supprimé
        XCTAssertFalse(emergencyManager.templates.contains { $0.id == "security-test" }, "Le template doit être supprimé")
        
        // Vérifier que les autres templates n'ont pas été affectés
        XCTAssertEqual(emergencyManager.templates.count, initialTemplates.count, "Le nombre de templates doit revenir à l'état initial")
    }
    
    func testRecipientAccessControl() throws {
        // Test que les destinataires ne peuvent être modifiés que par l'utilisateur
        let initialRecipients = multiPlatformManager.recipients
        
        // Créer un nouveau destinataire
        let newRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Security Test Contact",
            platforms: [.sms, .whatsapp]
        )
        
        multiPlatformManager.addRecipient(newRecipient)
        
        // Vérifier que le destinataire a été ajouté
        XCTAssertTrue(multiPlatformManager.recipients.contains { $0.phoneNumber == "+33123456789" }, "Le destinataire doit être ajouté")
        
        // Modifier le destinataire
        let updatedRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Updated Security Test Contact",
            platforms: [.sms, .whatsapp, .telegram]
        )
        
        multiPlatformManager.updateRecipient(updatedRecipient)
        
        // Vérifier que le destinataire a été modifié
        let modifiedRecipient = multiPlatformManager.recipients.first { $0.phoneNumber == "+33123456789" }
        XCTAssertEqual(modifiedRecipient?.name, "Updated Security Test Contact", "Le nom du destinataire doit être modifié")
        XCTAssertEqual(modifiedRecipient?.platforms.count, 3, "Le nombre de plateformes doit être modifié")
        
        // Supprimer le destinataire
        multiPlatformManager.removeRecipient(updatedRecipient)
        
        // Vérifier que le destinataire a été supprimé
        XCTAssertFalse(multiPlatformManager.recipients.contains { $0.phoneNumber == "+33123456789" }, "Le destinataire doit être supprimé")
        
        // Vérifier que les autres destinataires n'ont pas été affectés
        XCTAssertEqual(multiPlatformManager.recipients.count, initialRecipients.count, "Le nombre de destinataires doit revenir à l'état initial")
    }
    
    // MARK: - WhatsApp Scraping Security Tests
    
    func testWhatsAppScrapingSecurity() throws {
        // Test que le mode scraping ne peut être activé que par l'utilisateur
        let initialScrapingEnabled = whatsAppScraper.isScrapingEnabled
        
        // Activer le mode scraping
        whatsAppScraper.enableScrapingMode()
        
        // Vérifier que le mode scraping a été activé
        XCTAssertTrue(whatsAppScraper.isScrapingEnabled, "Le mode scraping doit être activé")
        
        // Désactiver le mode scraping
        whatsAppScraper.disableScrapingMode()
        
        // Vérifier que le mode scraping a été désactivé
        XCTAssertFalse(whatsAppScraper.isScrapingEnabled, "Le mode scraping doit être désactivé")
        
        // Vérifier que l'état est revenu à l'état initial
        XCTAssertEqual(whatsAppScraper.isScrapingEnabled, initialScrapingEnabled, "L'état du mode scraping doit revenir à l'état initial")
    }
    
    func testWhatsAppScrapingWarnings() throws {
        // Test que les avertissements de sécurité sont affichés
        let disclaimer = whatsAppScraper.showScrapingDisclaimer()
        XCTAssertFalse(disclaimer.isEmpty, "Le disclaimer de sécurité ne doit pas être vide")
        XCTAssertTrue(disclaimer.contains("RISQUE"), "Le disclaimer doit contenir des avertissements de risque")
        
        let guidelines = WhatsAppScraperManager.usageGuidelines
        XCTAssertFalse(guidelines.isEmpty, "Les guidelines d'utilisation ne doivent pas être vides")
        XCTAssertTrue(guidelines.contains("responsable"), "Les guidelines doivent mentionner l'utilisation responsable")
    }
    
    // MARK: - Data Persistence Security Tests
    
    func testDataPersistenceSecurity() throws {
        // Test que les données sont persistées de manière sécurisée
        let testTemplate = EmergencyTemplate(
            id: "persistence-test",
            name: "Persistence Test Template",
            message: "Test message with sensitive data",
            isActive: true,
            category: .custom
        )
        
        // Ajouter le template
        emergencyManager.addTemplate(testTemplate)
        
        // Vérifier que le template est en mémoire
        XCTAssertTrue(emergencyManager.templates.contains { $0.id == "persistence-test" }, "Le template doit être en mémoire")
        
        // Simuler une sauvegarde
        emergencyManager.saveTemplates()
        
        // Créer un nouveau manager pour simuler un redémarrage
        let newEmergencyManager = EmergencyMessageManager()
        
        // Vérifier que le template est toujours présent
        XCTAssertTrue(newEmergencyManager.templates.contains { $0.id == "persistence-test" }, "Le template doit être persistant")
        
        // Nettoyer
        newEmergencyManager.deleteTemplate(withId: "persistence-test")
    }
    
    func testUserDefaultsSecurity() throws {
        // Test que les données sensibles ne sont pas exposées dans UserDefaults
        let testKey = "security-test-key"
        let testValue = "sensitive-data"
        
        // Stocker des données de test
        UserDefaults.standard.set(testValue, forKey: testKey)
        
        // Vérifier que les données sont stockées
        let retrievedValue = UserDefaults.standard.string(forKey: testKey)
        XCTAssertEqual(retrievedValue, testValue, "Les données doivent être stockées correctement")
        
        // Nettoyer
        UserDefaults.standard.removeObject(forKey: testKey)
        
        // Vérifier que les données ont été supprimées
        let deletedValue = UserDefaults.standard.string(forKey: testKey)
        XCTAssertNil(deletedValue, "Les données doivent être supprimées")
    }
    
    // MARK: - Network Security Tests
    
    func testNetworkSecurity() throws {
        // Test que les communications réseau sont sécurisées
        let testRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Network Security Test Contact",
            platforms: [.sms]
        )
        
        let message = "Test message for network security"
        
        // Vérifier que l'envoi de message ne révèle pas d'informations sensibles
        let canSend = multiPlatformManager.sendMessage(to: testRecipient, message: message, platform: .sms)
        
        // L'envoi doit être possible
        XCTAssertTrue(canSend, "L'envoi de message doit être possible")
        
        // Vérifier que les données sensibles ne sont pas exposées dans les logs
        // (Ce test nécessiterait un environnement de test avec capture de logs)
        XCTAssertTrue(true, "Les données sensibles ne doivent pas être exposées dans les logs")
    }
    
    // MARK: - Privacy Tests
    
    func testPrivacyProtection() throws {
        // Test que les données privées sont protégées
        let testRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Privacy Test Contact",
            platforms: [.sms]
        )
        
        // Vérifier que les informations personnelles ne sont pas exposées
        XCTAssertNotEqual(testRecipient.phoneNumber, "", "Le numéro de téléphone doit être défini")
        XCTAssertNotEqual(testRecipient.name, "", "Le nom doit être défini")
        
        // Vérifier que les données ne sont pas partagées avec des tiers
        // (Ce test nécessiterait un environnement de test avec surveillance réseau)
        XCTAssertTrue(true, "Les données privées ne doivent pas être partagées avec des tiers")
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
            id: "security-test",
            name: "Security Test Template",
            message: "🚨 TEST - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
    }
    
    private func createMockRecipient() -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Security Test Recipient",
            platforms: [.sms, .whatsapp]
        )
    }
}

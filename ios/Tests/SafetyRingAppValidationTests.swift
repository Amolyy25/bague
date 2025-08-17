import XCTest
@testable import SafetyRingApp
import Foundation

final class SafetyRingAppValidationTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    var locationManager: LocationManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        multiPlatformManager = MultiPlatformMessageManager()
        locationManager = LocationManager()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        multiPlatformManager = nil
        locationManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Phone Number Validation Tests
    
    func testValidPhoneNumbers() throws {
        // Test des numéros de téléphone valides
        let validPhoneNumbers = [
            "17",           // Police française
            "15",           // SAMU français
            "18",           // Pompiers français
            "+33123456789", // Numéro français avec indicatif
            "0123456789",   // Numéro français sans indicatif
            "+1234567890",  // Numéro américain
            "+442071234567" // Numéro britannique
        ]
        
        for phoneNumber in validPhoneNumbers {
            let recipient = MessageRecipient(
                phoneNumber: phoneNumber,
                name: "Test \(phoneNumber)",
                platforms: [.sms]
            )
            
            XCTAssertEqual(recipient.phoneNumber, phoneNumber, "Le numéro de téléphone doit être correctement stocké")
            XCTAssertTrue(recipient.phoneNumber.count >= 2, "Le numéro de téléphone doit avoir au moins 2 chiffres")
        }
    }
    
    func testInvalidPhoneNumbers() throws {
        // Test des numéros de téléphone invalides
        let invalidPhoneNumbers = [
            "",           // Vide
            "abc",        // Lettres
            "123",        // Trop court
            "12345678901234567890", // Trop long
            "12-34-56",   // Caractères spéciaux non autorisés
            "12 34 56"    // Espaces
        ]
        
        for phoneNumber in invalidPhoneNumbers {
            // Vérifier que la validation rejette les numéros invalides
            let isValid = validatePhoneNumber(phoneNumber)
            XCTAssertFalse(isValid, "Le numéro '\(phoneNumber)' doit être rejeté")
        }
    }
    
    func testEmergencyPhoneNumbers() throws {
        // Test des numéros d'urgence spéciaux
        let emergencyNumbers = ["17", "15", "18", "112", "911", "999"]
        
        for number in emergencyNumbers {
            let recipient = MessageRecipient(
                phoneNumber: number,
                name: "Emergency \(number)",
                platforms: [.sms],
                isEmergency: true
            )
            
            XCTAssertTrue(recipient.isEmergency, "Le numéro \(number) doit être marqué comme d'urgence")
            XCTAssertTrue(recipient.platforms.contains(.sms), "Les numéros d'urgence doivent supporter SMS")
        }
    }
    
    // MARK: - Message Content Validation Tests
    
    func testValidMessageContent() throws {
        // Test du contenu des messages valides
        let validMessages = [
            "🚨 ALERTE URGENCE - J'ai besoin d'aide !",
            "Urgence médicale - Assistance requise",
            "Accident survenu - Secours nécessaire",
            "Situation dangereuse détectée",
            "Test de message normal"
        ]
        
        for message in validMessages {
            let isValid = validateMessageContent(message)
            XCTAssertTrue(isValid, "Le message '\(message)' doit être valide")
        }
    }
    
    func testInvalidMessageContent() throws {
        // Test du contenu des messages invalides
        let invalidMessages = [
            "",                    // Vide
            String(repeating: "a", count: 5000), // Trop long
            "   ",                // Seulement des espaces
            "\n\n\n",             // Seulement des retours à la ligne
            String(repeating: "🚨", count: 100) // Trop d'emojis
        ]
        
        for message in invalidMessages {
            let isValid = validateMessageContent(message)
            XCTAssertFalse(isValid, "Le message '\(message.prefix(20))' doit être rejeté")
        }
    }
    
    func testMessageLengthLimits() throws {
        // Test des limites de longueur des messages
        let shortMessage = "Test court"
        let mediumMessage = String(repeating: "a", count: 100)
        let longMessage = String(repeating: "b", count: 1000)
        let veryLongMessage = String(repeating: "c", count: 5000)
        
        XCTAssertTrue(validateMessageContent(shortMessage), "Le message court doit être valide")
        XCTAssertTrue(validateMessageContent(mediumMessage), "Le message moyen doit être valide")
        XCTAssertTrue(validateMessageContent(longMessage), "Le message long doit être valide")
        XCTAssertFalse(validateMessageContent(veryLongMessage), "Le message très long doit être rejeté")
    }
    
    // MARK: - Template Validation Tests
    
    func testValidTemplateIDs() throws {
        // Test des IDs de templates valides
        let validTemplateIDs = [
            "aggression",
            "medical",
            "accident",
            "danger",
            "custom-template",
            "template_123",
            "template-456"
        ]
        
        for templateID in validTemplateIDs {
            let isValid = validateTemplateID(templateID)
            XCTAssertTrue(isValid, "L'ID de template '\(templateID)' doit être valide")
        }
    }
    
    func testInvalidTemplateIDs() throws {
        // Test des IDs de templates invalides
        let invalidTemplateIDs = [
            "",           // Vide
            "a",          // Trop court
            "template with spaces", // Espaces
            "template@#$%",        // Caractères spéciaux
            String(repeating: "a", count: 100) // Trop long
        ]
        
        for templateID in invalidTemplateIDs {
            let isValid = validateTemplateID(templateID)
            XCTAssertFalse(isValid, "L'ID de template '\(templateID)' doit être rejeté")
        }
    }
    
    func testTemplateNameValidation() throws {
        // Test des noms de templates
        let validNames = [
            "🚨 Agression",
            "🏥 Urgence Médicale",
            "🚗 Accident de la Route",
            "⚠️ Danger Immédiat",
            "Template Personnalisé"
        ]
        
        for name in validNames {
            let isValid = validateTemplateName(name)
            XCTAssertTrue(isValid, "Le nom de template '\(name)' doit être valide")
        }
        
        let invalidNames = [
            "",                    // Vide
            "   ",                // Seulement des espaces
            String(repeating: "a", count: 200) // Trop long
        ]
        
        for name in invalidNames {
            let isValid = validateTemplateName(name)
            XCTAssertFalse(isValid, "Le nom de template '\(name)' doit être rejeté")
        }
    }
    
    // MARK: - Location Validation Tests
    
    func testValidCoordinates() throws {
        // Test des coordonnées GPS valides
        let validCoordinates = [
            (48.8566, 2.3522),   // Paris, France
            (40.7128, -74.0060), // New York, USA
            (51.5074, -0.1278),  // London, UK
            (35.6762, 139.6503), // Tokyo, Japan
            (-33.8688, 151.2093) // Sydney, Australia
        ]
        
        for (lat, lon) in validCoordinates {
            let isValid = validateCoordinates(latitude: lat, longitude: lon)
            XCTAssertTrue(isValid, "Les coordonnées (\(lat), \(lon)) doivent être valides")
        }
    }
    
    func testInvalidCoordinates() throws {
        // Test des coordonnées GPS invalides
        let invalidCoordinates = [
            (91.0, 0.0),    // Latitude > 90
            (-91.0, 0.0),   // Latitude < -90
            (0.0, 181.0),   // Longitude > 180
            (0.0, -181.0),  // Longitude < -180
            (Double.nan, 0.0), // NaN
            (0.0, Double.infinity) // Infini
        ]
        
        for (lat, lon) in invalidCoordinates {
            let isValid = validateCoordinates(latitude: lat, longitude: lon)
            XCTAssertFalse(isValid, "Les coordonnées (\(lat), \(lon)) doivent être rejetées")
        }
    }
    
    func testAddressValidation() throws {
        // Test des adresses valides
        let validAddresses = [
            "1 Rue de la Paix, 75001 Paris, France",
            "123 Main Street, New York, NY 10001, USA",
            "10 Downing Street, London, UK",
            "東京都渋谷区, Japan",
            "Sydney Opera House, Sydney, Australia"
        ]
        
        for address in validAddresses {
            let isValid = validateAddress(address)
            XCTAssertTrue(isValid, "L'adresse '\(address)' doit être valide")
        }
        
        let invalidAddresses = [
            "",                    // Vide
            "   ",                // Seulement des espaces
            String(repeating: "a", count: 1000) // Trop long
        ]
        
        for address in invalidAddresses {
            let isValid = validateAddress(address)
            XCTAssertFalse(isValid, "L'adresse '\(address)' doit être rejetée")
        }
    }
    
    // MARK: - Platform Validation Tests
    
    func testValidPlatforms() throws {
        // Test des plateformes valides
        let validPlatforms: [MessagePlatform] = [.sms, .whatsapp, .telegram, .signal]
        
        for platform in validPlatforms {
            let isValid = validatePlatform(platform)
            XCTAssertTrue(isValid, "La plateforme '\(platform.rawValue)' doit être valide")
        }
    }
    
    func testPlatformCompatibility() throws {
        // Test de la compatibilité des plateformes
        let testRecipient = MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test Recipient",
            platforms: [.sms, .whatsapp]
        )
        
        // Vérifier que les plateformes sont correctement assignées
        XCTAssertTrue(testRecipient.platforms.contains(.sms), "Le destinataire doit supporter SMS")
        XCTAssertTrue(testRecipient.platforms.contains(.whatsapp), "Le destinataire doit supporter WhatsApp")
        XCTAssertFalse(testRecipient.platforms.contains(.telegram), "Le destinataire ne doit pas supporter Telegram par défaut")
    }
    
    // MARK: - Category Validation Tests
    
    func testValidCategories() throws {
        // Test des catégories valides
        let validCategories: [EmergencyCategory] = [.aggression, .medical, .accident, .danger, .custom]
        
        for category in validCategories {
            let isValid = validateCategory(category)
            XCTAssertTrue(isValid, "La catégorie '\(category.name)' doit être valide")
        }
    }
    
    func testCategoryProperties() throws {
        // Test des propriétés des catégories
        for category in EmergencyCategory.allCases {
            XCTAssertFalse(category.name.isEmpty, "La catégorie doit avoir un nom")
            XCTAssertFalse(category.icon.isEmpty, "La catégorie doit avoir une icône")
            XCTAssertNotNil(category.color, "La catégorie doit avoir une couleur")
            XCTAssertTrue(category.priority >= 1 && category.priority <= 5, "La priorité doit être entre 1 et 5")
        }
    }
    
    // MARK: - WhatsApp Scraping Validation Tests
    
    func testWhatsAppScrapingSettings() throws {
        // Test des paramètres de scraping WhatsApp
        let scraper = WhatsAppScraperManager()
        
        // Vérifier les valeurs par défaut
        XCTAssertFalse(scraper.isScrapingEnabled, "Le scraping WhatsApp doit être désactivé par défaut")
        XCTAssertEqual(scraper.usageCount, 0, "Le compteur d'utilisation doit être à 0 par défaut")
        XCTAssertNil(scraper.lastUsed, "La dernière utilisation doit être nil par défaut")
    }
    
    func testWhatsAppScrapingWarnings() throws {
        // Test des avertissements de scraping
        let scraper = WhatsAppScraperManager()
        
        // Vérifier que les avertissements sont présents
        XCTAssertFalse(scraper.warnings.isEmpty, "Il doit y avoir des avertissements")
        
        let warningTexts = scraper.warnings.map { $0.text }
        XCTAssertTrue(warningTexts.contains { $0.contains("bannissement") }, "Il doit y avoir un avertissement sur le bannissement")
        XCTAssertTrue(warningTexts.contains { $0.contains("conditions") }, "Il doit y avoir un avertissement sur les conditions d'utilisation")
    }
    
    // MARK: - Data Persistence Validation Tests
    
    func testUserDefaultsValidation() throws {
        // Test de la validation des UserDefaults
        let testKey = "test_validation_key"
        let testValue = "test_value"
        
        // Écrire une valeur
        UserDefaults.standard.set(testValue, forKey: testKey)
        
        // Vérifier que la valeur peut être lue
        let readValue = UserDefaults.standard.string(forKey: testKey)
        XCTAssertEqual(readValue, testValue, "La valeur lue doit correspondre à la valeur écrite")
        
        // Nettoyer
        UserDefaults.standard.removeObject(forKey: testKey)
    }
    
    func testJSONEncodingValidation() throws {
        // Test de l'encodage JSON
        let testTemplate = EmergencyTemplate(
            id: "test-json",
            name: "Test JSON",
            message: "Test message",
            isActive: true,
            category: .custom
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(testTemplate)
            XCTAssertFalse(data.isEmpty, "Les données encodées ne doivent pas être vides")
            
            let decoder = JSONDecoder()
            let decodedTemplate = try decoder.decode(EmergencyTemplate.self, from: data)
            XCTAssertEqual(decodedTemplate.id, testTemplate.id, "Le template décodé doit avoir le même ID")
            XCTAssertEqual(decodedTemplate.name, testTemplate.name, "Le template décodé doit avoir le même nom")
        } catch {
            XCTFail("L'encodage/décodage JSON ne doit pas échouer: \(error)")
        }
    }
    
    // MARK: - Input Sanitization Tests
    
    func testPhoneNumberSanitization() throws {
        // Test de la sanitisation des numéros de téléphone
        let dirtyNumbers = [
            "  +33 1 23 45 67 89  ",
            "(+33) 1-23-45-67-89",
            "+33.1.23.45.67.89",
            "  +33 1 23 45 67 89  \n"
        ]
        
        let expectedClean = "+33123456789"
        
        for dirtyNumber in dirtyNumbers {
            let cleanNumber = sanitizePhoneNumber(dirtyNumber)
            XCTAssertEqual(cleanNumber, expectedClean, "Le numéro '\(dirtyNumber)' doit être nettoyé")
        }
    }
    
    func testMessageSanitization() throws {
        // Test de la sanitisation des messages
        let dirtyMessages = [
            "  Message avec espaces  ",
            "\n\nMessage avec retours à la ligne\n\n",
            "Message\tavec\ttabulations",
            "Message\r\navec\r\nretours\r\nà\r\nla\r\nligne"
        ]
        
        for dirtyMessage in dirtyMessages {
            let cleanMessage = sanitizeMessage(dirtyMessage)
            XCTAssertFalse(cleanMessage.hasPrefix(" "), "Le message ne doit pas commencer par un espace")
            XCTAssertFalse(cleanMessage.hasSuffix(" "), "Le message ne doit pas se terminer par un espace")
            XCTAssertFalse(cleanMessage.contains("\t"), "Le message ne doit pas contenir de tabulations")
            XCTAssertFalse(cleanMessage.contains("\r"), "Le message ne doit pas contenir de retours chariot")
        }
    }
    
    func testTemplateNameSanitization() throws {
        // Test de la sanitisation des noms de templates
        let dirtyNames = [
            "  Template Name  ",
            "\nTemplate\nName\n",
            "Template\tName",
            "Template\r\nName"
        ]
        
        for dirtyName in dirtyNames {
            let cleanName = sanitizeTemplateName(dirtyName)
            XCTAssertFalse(cleanName.hasPrefix(" "), "Le nom ne doit pas commencer par un espace")
            XCTAssertFalse(cleanName.hasSuffix(" "), "Le nom ne doit pas se terminer par un espace")
            XCTAssertFalse(cleanName.contains("\t"), "Le nom ne doit pas contenir de tabulations")
            XCTAssertFalse(cleanName.contains("\r"), "Le nom ne doit pas contenir de retours chariot")
        }
    }
    
    // MARK: - Test Helpers
    
    private func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Validation basique des numéros de téléphone
        let cleanNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanNumber.isEmpty else { return false }
        guard cleanNumber.count >= 2 else { return false }
        guard cleanNumber.count <= 20 else { return false }
        
        // Vérifier qu'il n'y a que des chiffres, +, -, (, ), et espaces
        let allowedCharacters = CharacterSet(charactersIn: "0123456789+-() ")
        let phoneCharacterSet = CharacterSet(charactersIn: cleanNumber)
        
        return phoneCharacterSet.isSubset(of: allowedCharacters)
    }
    
    private func validateMessageContent(_ message: String) -> Bool {
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanMessage.isEmpty else { return false }
        guard cleanMessage.count <= 4000 else { return false }
        
        return true
    }
    
    private func validateTemplateID(_ templateID: String) -> Bool {
        let cleanID = templateID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanID.isEmpty else { return false }
        guard cleanID.count >= 3 else { return false }
        guard cleanID.count <= 50 else { return false }
        
        // Vérifier qu'il n'y a que des lettres, chiffres, tirets et underscores
        let allowedCharacters = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: cleanID)
        
        return idCharacterSet.isSubset(of: allowedCharacters)
    }
    
    private func validateTemplateName(_ name: String) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanName.isEmpty else { return false }
        guard cleanName.count <= 100 else { return false }
        
        return true
    }
    
    private func validateCoordinates(latitude: Double, longitude: Double) -> Bool {
        guard !latitude.isNaN && !longitude.isNaN else { return false }
        guard !latitude.isInfinite && !longitude.isInfinite else { return false }
        guard latitude >= -90 && latitude <= 90 else { return false }
        guard longitude >= -180 && longitude <= 180 else { return false }
        
        return true
    }
    
    private func validateAddress(_ address: String) -> Bool {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanAddress.isEmpty else { return false }
        guard cleanAddress.count <= 500 else { return false }
        
        return true
    }
    
    private func validatePlatform(_ platform: MessagePlatform) -> Bool {
        return !platform.rawValue.isEmpty && !platform.icon.isEmpty && !platform.color.isEmpty
    }
    
    private func validateCategory(_ category: EmergencyCategory) -> Bool {
        return !category.name.isEmpty && !category.icon.isEmpty && category.color != nil
    }
    
    private func sanitizePhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
    private func sanitizeMessage(_ message: String) -> String {
        return message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    private func sanitizeTemplateName(_ name: String) -> String {
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

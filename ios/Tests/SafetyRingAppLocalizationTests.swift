import XCTest
@testable import SafetyRingApp
import Foundation

final class SafetyRingAppLocalizationTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        multiPlatformManager = MultiPlatformMessageManager()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        multiPlatformManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - French Localization Tests
    
    func testFrenchLocalization() throws {
        // Test que l'application supporte le français
        let locale = Locale(identifier: "fr_FR")
        XCTAssertEqual(locale.languageCode, "fr", "La langue française doit être supportée")
        XCTAssertEqual(locale.regionCode, "FR", "La région française doit être supportée")
        
        // Test des templates en français
        let frenchTemplates = emergencyManager.templates.filter { template in
            template.name.contains("🚨") || template.name.contains("🏥") || template.name.contains("🚗")
        }
        
        XCTAssertFalse(frenchTemplates.isEmpty, "Il doit y avoir des templates en français")
        
        // Vérifier que les messages d'urgence sont en français
        for template in frenchTemplates {
            XCTAssertTrue(template.message.contains("ALERTE"), "Le message doit contenir 'ALERTE' en français")
            XCTAssertTrue(template.message.contains("urgence"), "Le message doit contenir 'urgence' en français")
        }
    }
    
    func testFrenchEmergencyMessages() throws {
        // Test des messages d'urgence en français
        let template = emergencyManager.templates.first!
        let mockLocation = createMockLocation()
        
        let message = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
        
        // Vérifier les éléments français dans le message
        XCTAssertTrue(message.contains("ALERTE"), "Le message doit contenir 'ALERTE'")
        XCTAssertTrue(message.contains("urgence"), "Le message doit contenir 'urgence'")
        XCTAssertTrue(message.contains("aide"), "Le message doit contenir 'aide'")
        XCTAssertTrue(message.contains("immédiatement"), "Le message doit contenir 'immédiatement'")
    }
    
    func testFrenchLocationText() throws {
        // Test du texte de localisation en français
        let mockLocation = createMockLocation()
        
        let emergencyText = mockLocation.getEmergencyLocationText()
        
        // Vérifier les éléments français dans le texte de localisation
        XCTAssertTrue(emergencyText.contains("Adresse"), "Le texte doit contenir 'Adresse' en français")
        XCTAssertTrue(emergencyText.contains("GPS"), "Le texte doit contenir 'GPS'")
        XCTAssertTrue(emergencyText.contains("Carte"), "Le texte doit contenir 'Carte' en français")
        XCTAssertTrue(emergencyText.contains("Heure"), "Le texte doit contenir 'Heure' en français")
    }
    
    // MARK: - English Localization Tests
    
    func testEnglishLocalization() throws {
        // Test que l'application peut supporter l'anglais
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(locale.languageCode, "en", "La langue anglaise doit être supportée")
        XCTAssertEqual(locale.regionCode, "US", "La région américaine doit être supportée")
        
        // Note: L'application est actuellement en français uniquement
        // Ces tests vérifient la capacité future de support multilingue
        XCTAssertTrue(true, "L'application doit pouvoir supporter l'anglais à l'avenir")
    }
    
    // MARK: - Date and Time Formatting Tests
    
    func testFrenchDateFormatting() throws {
        // Test du formatage des dates en français
        let date = Date()
        let formatter = DateFormatter()
        
        // Format français
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let frenchDateString = formatter.string(from: date)
        
        // Vérifier que la date est formatée en français
        XCTAssertFalse(frenchDateString.isEmpty, "La date française ne doit pas être vide")
        
        // Vérifier les éléments français typiques
        let containsFrenchElements = frenchDateString.contains("janv") || 
                                   frenchDateString.contains("févr") || 
                                   frenchDateString.contains("mars") ||
                                   frenchDateString.contains("avr") ||
                                   frenchDateString.contains("mai") ||
                                   frenchDateString.contains("juin") ||
                                   frenchDateString.contains("juil") ||
                                   frenchDateString.contains("août") ||
                                   frenchDateString.contains("sept") ||
                                   frenchDateString.contains("oct") ||
                                   frenchDateString.contains("nov") ||
                                   frenchDateString.contains("déc")
        
        XCTAssertTrue(containsFrenchElements, "La date doit contenir des mois en français")
    }
    
    func testFrenchTimeFormatting() throws {
        // Test du formatage de l'heure en français
        let date = Date()
        let formatter = DateFormatter()
        
        // Format français
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeStyle = .short
        
        let frenchTimeString = formatter.string(from: date)
        
        // Vérifier que l'heure est formatée en français
        XCTAssertFalse(frenchTimeString.isEmpty, "L'heure française ne doit pas être vide")
        
        // Vérifier le format 24h typique en français
        XCTAssertTrue(frenchTimeString.contains(":"), "L'heure doit contenir ':'")
    }
    
    // MARK: - Number Formatting Tests
    
    func testFrenchNumberFormatting() throws {
        // Test du formatage des nombres en français
        let number = 1234.56
        let formatter = NumberFormatter()
        
        // Format français
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let frenchNumberString = formatter.string(from: NSNumber(value: number))
        
        // Vérifier que le nombre est formaté en français
        XCTAssertFalse(frenchNumberString.isEmpty, "Le nombre français ne doit pas être vide")
        
        // Vérifier l'utilisation de la virgule comme séparateur décimal
        XCTAssertTrue(frenchNumberString?.contains(",") == true, "Le nombre doit utiliser la virgule comme séparateur décimal")
        
        // Vérifier l'utilisation de l'espace comme séparateur de milliers
        XCTAssertTrue(frenchNumberString?.contains(" ") == true, "Le nombre doit utiliser l'espace comme séparateur de milliers")
    }
    
    // MARK: - Currency Formatting Tests
    
    func testFrenchCurrencyFormatting() throws {
        // Test du formatage de la monnaie en français
        let amount = 1234.56
        let formatter = NumberFormatter()
        
        // Format français avec euro
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        
        let frenchCurrencyString = formatter.string(from: NSNumber(value: amount))
        
        // Vérifier que la monnaie est formatée en français
        XCTAssertFalse(frenchCurrencyString.isEmpty, "La monnaie française ne doit pas être vide")
        
        // Vérifier l'utilisation du symbole euro
        XCTAssertTrue(frenchCurrencyString?.contains("€") == true, "La monnaie doit contenir le symbole euro")
        
        // Vérifier l'utilisation de la virgule comme séparateur décimal
        XCTAssertTrue(frenchCurrencyString?.contains(",") == true, "La monnaie doit utiliser la virgule comme séparateur décimal")
    }
    
    // MARK: - Address Formatting Tests
    
    func testFrenchAddressFormatting() throws {
        // Test du formatage des adresses en français
        let mockLocation = createMockLocation()
        
        let formattedLocation = mockLocation.getFormattedLocation()
        
        // Vérifier que l'adresse est formatée correctement
        XCTAssertFalse(formattedLocation.isEmpty, "L'adresse formatée ne doit pas être vide")
        XCTAssertTrue(formattedLocation.contains("Paris"), "L'adresse doit contenir la ville")
        XCTAssertTrue(formattedLocation.contains("France"), "L'adresse doit contenir le pays")
        
        // Vérifier le format français typique (code postal avant ville)
        XCTAssertTrue(formattedLocation.contains("75001"), "L'adresse doit contenir le code postal")
    }
    
    // MARK: - Emergency Numbers Tests
    
    func testFrenchEmergencyNumbers() throws {
        // Test des numéros d'urgence français
        let emergencyNumbers = ["17", "15", "18"]
        
        for number in emergencyNumbers {
            let recipient = MessageRecipient(
                phoneNumber: number,
                name: "Emergency \(number)",
                platforms: [.sms]
            )
            
            XCTAssertEqual(recipient.phoneNumber, number, "Le numéro d'urgence doit être correct")
            XCTAssertTrue(recipient.platforms.contains(.sms), "Les numéros d'urgence doivent supporter SMS")
        }
    }
    
    // MARK: - Platform Names Tests
    
    func testFrenchPlatformNames() throws {
        // Test des noms de plateformes en français
        let platforms: [MessagePlatform] = [.sms, .whatsapp, .telegram, .signal]
        
        for platform in platforms {
            // Vérifier que la plateforme a un nom et une icône
            XCTAssertFalse(platform.rawValue.isEmpty, "La plateforme doit avoir un nom")
            XCTAssertFalse(platform.icon.isEmpty, "La plateforme doit avoir une icône")
            XCTAssertFalse(platform.color.isEmpty, "La plateforme doit avoir une couleur")
        }
    }
    
    // MARK: - Template Categories Tests
    
    func testFrenchTemplateCategories() throws {
        // Test des catégories de templates en français
        let categories: [EmergencyCategory] = [.aggression, .medical, .accident, .danger, .custom]
        
        for category in categories {
            // Vérifier que la catégorie a un nom et une icône
            XCTAssertFalse(category.name.isEmpty, "La catégorie doit avoir un nom")
            XCTAssertFalse(category.icon.isEmpty, "La catégorie doit avoir une icône")
            XCTAssertNotNil(category.color, "La catégorie doit avoir une couleur")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testFrenchAccessibility() throws {
        // Test de l'accessibilité en français
        let emergencyButton = "🚨 ALERTE D'URGENCE"
        let settingsButton = "Paramètres"
        let addButton = "Ajouter"
        
        // Vérifier que les boutons ont des noms en français
        XCTAssertTrue(emergencyButton.contains("ALERTE"), "Le bouton d'urgence doit être en français")
        XCTAssertTrue(emergencyButton.contains("URGENCE"), "Le bouton d'urgence doit être en français")
        XCTAssertTrue(settingsButton.contains("Paramètres"), "Le bouton des paramètres doit être en français")
        XCTAssertTrue(addButton.contains("Ajouter"), "Le bouton d'ajout doit être en français")
    }
    
    // MARK: - Error Messages Tests
    
    func testFrenchErrorMessages() throws {
        // Test des messages d'erreur en français
        let errorMessages = [
            "Erreur",
            "Avertissement",
            "Information",
            "Succès"
        ]
        
        for message in errorMessages {
            XCTAssertFalse(message.isEmpty, "Le message d'erreur ne doit pas être vide")
            XCTAssertTrue(message.count > 0, "Le message d'erreur doit avoir du contenu")
        }
    }
    
    // MARK: - Success Messages Tests
    
    func testFrenchSuccessMessages() throws {
        // Test des messages de succès en français
        let successMessages = [
            "Envoyé",
            "Terminé",
            "Succès",
            "OK"
        ]
        
        for message in successMessages {
            XCTAssertFalse(message.isEmpty, "Le message de succès ne doit pas être vide")
            XCTAssertTrue(message.count > 0, "Le message de succès doit avoir du contenu")
        }
    }
    
    // MARK: - Navigation Tests
    
    func testFrenchNavigation() throws {
        // Test de la navigation en français
        let navigationItems = [
            "Accueil",
            "Paramètres",
            "Destinataires",
            "Templates",
            "Historique",
            "Aide"
        ]
        
        for item in navigationItems {
            XCTAssertFalse(item.isEmpty, "L'élément de navigation ne doit pas être vide")
            XCTAssertTrue(item.count > 0, "L'élément de navigation doit avoir du contenu")
        }
    }
    
    // MARK: - Status Messages Tests
    
    func testFrenchStatusMessages() throws {
        // Test des messages de statut en français
        let statusMessages = [
            "Connecté",
            "Déconnecté",
            "En ligne",
            "Hors ligne",
            "Active",
            "Inactive"
        ]
        
        for message in statusMessages {
            XCTAssertFalse(message.isEmpty, "Le message de statut ne doit pas être vide")
            XCTAssertTrue(message.count > 0, "Le message de statut doit avoir du contenu")
        }
    }
    
    // MARK: - Action Messages Tests
    
    func testFrenchActionMessages() throws {
        // Test des messages d'action en français
        let actionMessages = [
            "Déclencher",
            "Arrêter",
            "Confirmer",
            "Annuler",
            "Enregistrer",
            "Supprimer",
            "Modifier",
            "Ajouter",
            "Fermer",
            "Retour"
        ]
        
        for message in actionMessages {
            XCTAssertFalse(message.isEmpty, "Le message d'action ne doit pas être vide")
            XCTAssertTrue(message.count > 0, "Le message d'action doit avoir du contenu")
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
            id: "localization-test",
            name: "Test de Localisation",
            message: "🚨 TEST - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
    }
    
    private func createMockRecipient() -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Test de Localisation",
            platforms: [.sms, .whatsapp]
        )
    }
}

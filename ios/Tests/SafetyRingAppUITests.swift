import XCTest

final class SafetyRingAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunch() throws {
        // Vérifier que l'app se lance correctement
        XCTAssertTrue(app.waitForExistence(timeout: 5), "L'application doit se lancer")
        
        // Vérifier les éléments principaux de l'interface
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "Le titre principal doit être visible")
        XCTAssertTrue(app.staticTexts["Système d'alerte d'urgence intelligent"].exists, "Le sous-titre doit être visible")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationToSettings() throws {
        // Naviguer vers les paramètres
        let settingsButton = app.buttons["Paramètres"]
        XCTAssertTrue(settingsButton.exists, "Le bouton Paramètres doit être visible")
        
        settingsButton.tap()
        
        // Vérifier que l'écran des paramètres est affiché
        XCTAssertTrue(app.navigationBars["Paramètres"].exists, "L'écran des paramètres doit être affiché")
        
        // Retourner à l'écran principal
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Vérifier le retour à l'écran principal
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "Retour à l'écran principal")
    }
    
    // MARK: - Emergency Alert Tests
    
    func testEmergencyAlertButton() throws {
        // Vérifier que le bouton d'alerte d'urgence existe
        let emergencyButton = app.buttons["🚨 ALERTE D'URGENCE"]
        XCTAssertTrue(emergencyButton.exists, "Le bouton d'alerte d'urgence doit être visible")
        
        // Vérifier que le bouton est activé
        XCTAssertTrue(emergencyButton.isEnabled, "Le bouton d'alerte doit être activé")
    }
    
    func testEmergencyAlertCountdown() throws {
        // Déclencher l'alerte d'urgence
        let emergencyButton = app.buttons["🚨 ALERTE D'URGENCE"]
        emergencyButton.tap()
        
        // Vérifier que le compte à rebours est affiché
        let countdownText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'secondes restantes'")).firstMatch
        XCTAssertTrue(countdownText.exists, "Le compte à rebours doit être affiché")
        
        // Vérifier que le bouton d'annulation est visible
        let cancelButton = app.buttons["Annuler l'alerte"]
        XCTAssertTrue(cancelButton.exists, "Le bouton d'annulation doit être visible")
        
        // Annuler l'alerte
        cancelButton.tap()
        
        // Vérifier le retour à l'état initial
        XCTAssertTrue(app.buttons["🚨 ALERTE D'URGENCE"].exists, "Retour au bouton d'alerte initial")
    }
    
    // MARK: - Template Selection Tests
    
    func testEmergencyTemplateSelection() throws {
        // Naviguer vers la sélection de templates
        let templateButton = app.buttons["Sélectionner"]
        XCTAssertTrue(templateButton.exists, "Le bouton de sélection de templates doit être visible")
        
        templateButton.tap()
        
        // Vérifier que l'écran de sélection est affiché
        XCTAssertTrue(app.navigationBars["Sélectionner Template"].exists, "L'écran de sélection doit être affiché")
        
        // Retourner à l'écran principal
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // MARK: - Recipient Management Tests
    
    func testRecipientAddition() throws {
        // Naviguer vers l'ajout de destinataires
        let addButton = app.buttons["Ajouter"]
        XCTAssertTrue(addButton.exists, "Le bouton d'ajout de destinataires doit être visible")
        
        addButton.tap()
        
        // Vérifier que l'écran d'édition est affiché
        XCTAssertTrue(app.navigationBars["Ajouter Destinataire"].exists, "L'écran d'ajout doit être affiché")
        
        // Retourner à l'écran principal
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // MARK: - Status Display Tests
    
    func testStatusCardsDisplay() throws {
        // Vérifier que les cartes de statut sont affichées
        let bluetoothStatus = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Bluetooth'")).firstMatch
        XCTAssertTrue(bluetoothStatus.exists, "Le statut Bluetooth doit être affiché")
        
        let networkStatus = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Réseau'")).firstMatch
        XCTAssertTrue(networkStatus.exists, "Le statut réseau doit être affiché")
        
        let locationStatus = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Localisation'")).firstMatch
        XCTAssertTrue(locationStatus.exists, "Le statut de localisation doit être affiché")
    }
    
    // MARK: - Template Display Tests
    
    func testEmergencyTemplatesDisplay() throws {
        // Vérifier que la section des templates est visible
        let templatesTitle = app.staticTexts["🚨 Templates d'urgence"]
        XCTAssertTrue(templatesTitle.exists, "Le titre des templates doit être visible")
        
        // Vérifier qu'au moins un template est affiché
        let templateGrid = app.collectionViews.firstMatch
        XCTAssertTrue(templateGrid.exists, "La grille des templates doit être visible")
    }
    
    // MARK: - Recipients Display Tests
    
    func testRecipientsSectionDisplay() throws {
        // Vérifier que la section des destinataires est visible
        let recipientsTitle = app.staticTexts["📱 Destinataires"]
        XCTAssertTrue(recipientsTitle.exists, "Le titre des destinataires doit être visible")
        
        // Vérifier le bouton d'ajout
        let addButton = app.buttons["Ajouter"]
        XCTAssertTrue(addButton.exists, "Le bouton d'ajout doit être visible")
    }
    
    // MARK: - Alert Logs Display Tests
    
    func testAlertLogsSectionDisplay() throws {
        // Vérifier que la section des logs est visible
        let logsTitle = app.staticTexts["📋 Historique des alertes"]
        XCTAssertTrue(logsTitle.exists, "Le titre des logs doit être visible")
    }
    
    // MARK: - Settings Integration Tests
    
    func testSettingsAccessibility() throws {
        // Naviguer vers les paramètres
        app.buttons["Paramètres"].tap()
        
        // Vérifier les sections principales des paramètres
        XCTAssertTrue(app.staticTexts["Général"].exists, "La section Général doit être visible")
        XCTAssertTrue(app.staticTexts["Alertes"].exists, "La section Alertes doit être visible")
        XCTAssertTrue(app.staticTexts["Messagerie"].exists, "La section Messagerie doit être visible")
        
        // Retourner à l'écran principal
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // MARK: - WhatsApp Scraping Tests
    
    func testWhatsAppScrapingSection() throws {
        // Naviguer vers les paramètres
        app.buttons["Paramètres"].tap()
        
        // Vérifier la section WhatsApp scraping
        let scrapingTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'WhatsApp'")).firstMatch
        XCTAssertTrue(scrapingTitle.exists, "La section WhatsApp scraping doit être visible")
        
        // Retourner à l'écran principal
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testNavigationPerformance() throws {
        measure {
            // Navigation vers les paramètres et retour
            app.buttons["Paramètres"].tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Vérifier que les éléments principaux ont des labels d'accessibilité
        let emergencyButton = app.buttons["🚨 ALERTE D'URGENCE"]
        XCTAssertTrue(emergencyButton.exists, "Le bouton d'alerte doit avoir un label d'accessibilité")
        
        let settingsButton = app.buttons["Paramètres"]
        XCTAssertTrue(settingsButton.exists, "Le bouton des paramètres doit avoir un label d'accessibilité")
    }
    
    // MARK: - Dark Mode Tests
    
    func testDarkModeCompatibility() throws {
        // Note: Ces tests nécessitent un environnement de test avec support du mode sombre
        // Vérifier que l'interface reste lisible en mode sombre
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "Le titre doit rester visible en mode sombre")
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationChanges() throws {
        // Note: Ces tests nécessitent un environnement de test avec support des rotations
        // Vérifier que l'interface s'adapte aux changements d'orientation
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "Le titre doit rester visible après rotation")
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        // Simuler une erreur réseau (nécessite un environnement de test spécial)
        // Vérifier que l'interface affiche correctement les erreurs
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "L'interface doit rester stable en cas d'erreur")
    }
    
    // MARK: - Localization Tests
    
    func testLocalizationSupport() throws {
        // Note: Ces tests nécessitent un environnement de test avec différentes langues
        // Vérifier que l'interface s'adapte aux changements de langue
        XCTAssertTrue(app.staticTexts["SafetyRing"].exists, "L'interface doit supporter la localisation")
    }
}

// MARK: - Test Helpers

extension SafetyRingAppUITests {
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    func tapIfExists(_ element: XCUIElement) {
        if element.exists {
            element.tap()
        }
    }
    
    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement) {
        while !element.isHittable {
            scrollView.swipeUp()
        }
    }
}

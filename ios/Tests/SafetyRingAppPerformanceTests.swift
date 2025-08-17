import XCTest
@testable import SafetyRingApp

final class SafetyRingAppPerformanceTests: XCTestCase {
    
    var emergencyManager: EmergencyMessageManager!
    var locationManager: LocationManager!
    var multiPlatformManager: MultiPlatformMessageManager!
    var whatsAppScraper: WhatsAppScraperManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        emergencyManager = EmergencyMessageManager()
        locationManager = LocationManager()
        multiPlatformManager = MultiPlatformMessageManager()
        whatsAppScraper = WhatsAppScraperManager()
    }
    
    override func tearDownWithError() throws {
        emergencyManager = nil
        locationManager = nil
        multiPlatformManager = nil
        whatsAppScraper = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Emergency Message Generation Performance
    
    func testEmergencyMessageGenerationPerformance() throws {
        // Préparer les données de test
        let mockLocation = createMockLocation()
        let template = emergencyManager.templates.first!
        
        measure {
            for _ in 0..<1000 {
                _ = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
            }
        }
    }
    
    func testCustomMessageGenerationPerformance() throws {
        let mockLocation = createMockLocation()
        
        measure {
            for _ in 0..<1000 {
                _ = emergencyManager.generateCustomMessage(location: mockLocation)
            }
        }
    }
    
    func testTemplateSearchPerformance() throws {
        measure {
            for _ in 0..<10000 {
                _ = emergencyManager.templates.filter { $0.isActive }
            }
        }
    }
    
    func testTemplateManagementPerformance() throws {
        let testTemplate = createMockEmergencyTemplate()
        
        measure {
            for i in 0..<100 {
                let template = EmergencyTemplate(
                    id: "perf-test-\(i)",
                    name: "Performance Test \(i)",
                    message: "Test message \(i)",
                    isActive: true,
                    category: .custom
                )
                
                emergencyManager.addTemplate(template)
                emergencyManager.updateTemplate(template)
                emergencyManager.deleteTemplate(withId: template.id)
            }
        }
    }
    
    // MARK: - Location Processing Performance
    
    func testLocationFormattingPerformance() throws {
        let mockLocation = createMockLocation()
        
        measure {
            for _ in 0..<1000 {
                _ = mockLocation.getFormattedLocation()
            }
        }
    }
    
    func testEmergencyLocationTextPerformance() throws {
        let mockLocation = createMockLocation()
        
        measure {
            for _ in 0..<1000 {
                _ = mockLocation.getEmergencyLocationText()
            }
        }
    }
    
    func testCoordinateProcessingPerformance() throws {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        ]
        
        measure {
            for _ in 0..<1000 {
                for coordinate in coordinates {
                    let location = LocationManager()
                    location.lastCoordinate = coordinate
                    _ = location.getFormattedLocation()
                }
            }
        }
    }
    
    // MARK: - Recipient Management Performance
    
    func testRecipientSearchPerformance() throws {
        // Créer de nombreux destinataires de test
        for i in 0..<1000 {
            let recipient = MessageRecipient(
                phoneNumber: "+33123456789\(i)",
                name: "Test Recipient \(i)",
                platforms: [.sms, .whatsapp]
            )
            multiPlatformManager.addRecipient(recipient)
        }
        
        measure {
            for _ in 0..<1000 {
                _ = multiPlatformManager.recipients.filter { $0.isActive }
                _ = multiPlatformManager.recipients.filter { $0.platforms.contains(.whatsapp) }
                _ = multiPlatformManager.recipients.first { $0.phoneNumber == "+331234567890" }
            }
        }
        
        // Nettoyer
        for i in 0..<1000 {
            let recipient = MessageRecipient(
                phoneNumber: "+33123456789\(i)",
                name: "Test Recipient \(i)",
                platforms: [.sms, .whatsapp]
            )
            multiPlatformManager.removeRecipient(recipient)
        }
    }
    
    func testRecipientAdditionPerformance() throws {
        measure {
            for i in 0..<1000 {
                let recipient = MessageRecipient(
                    phoneNumber: "+33123456789\(i)",
                    name: "Performance Test \(i)",
                    platforms: [.sms, .whatsapp, .telegram]
                )
                multiPlatformManager.addRecipient(recipient)
            }
        }
        
        // Nettoyer
        for i in 0..<1000 {
            let recipient = MessageRecipient(
                phoneNumber: "+33123456789\(i)",
                name: "Performance Test \(i)",
                platforms: [.sms, .whatsapp, .telegram]
            )
            multiPlatformManager.removeRecipient(recipient)
        }
    }
    
    func testPlatformAvailabilityCheckPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = multiPlatformManager.getAvailablePlatforms(for: "+33123456789")
            }
        }
    }
    
    // MARK: - Message Sending Performance
    
    func testMessageSendingPerformance() throws {
        let recipient = createMockRecipient()
        let message = "🚨 TEST - Message de test pour les performances"
        
        measure {
            for _ in 0..<1000 {
                _ = multiPlatformManager.sendMessage(to: recipient, message: message, platform: .sms)
            }
        }
    }
    
    func testMultiPlatformSendingPerformance() throws {
        let message = "🚨 TEST - Message multi-plateforme pour les performances"
        
        measure {
            for _ in 0..<1000 {
                multiPlatformManager.sendEmergencyMessageToAllRecipients(
                    message: message,
                    platform: .sms,
                    useScraping: false
                )
            }
        }
    }
    
    // MARK: - WhatsApp Scraping Performance
    
    func testWhatsAppScrapingInitializationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let scraper = WhatsAppScraperManager()
                _ = scraper.isScrapingEnabled
                _ = scraper.isWebViewReady
            }
        }
    }
    
    func testWhatsAppScrapingSettingsPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = whatsAppScraper.showScrapingDisclaimer()
                _ = whatsAppScraper.getScrapingStatus()
            }
        }
    }
    
    // MARK: - Data Persistence Performance
    
    func testUserDefaultsPerformance() throws {
        let testData = Array(0..<1000).map { "test-value-\($0)" }
        
        measure {
            for (index, value) in testData.enumerated() {
                UserDefaults.standard.set(value, forKey: "perf-test-\(index)")
            }
        }
        
        // Nettoyer
        for index in 0..<1000 {
            UserDefaults.standard.removeObject(forKey: "perf-test-\(index)")
        }
    }
    
    func testJSONEncodingPerformance() throws {
        let testTemplates = Array(0..<100).map { index in
            EmergencyTemplate(
                id: "perf-\(index)",
                name: "Performance Template \(index)",
                message: "Test message \(index) with {ADDRESS} and {GPS}",
                isActive: true,
                category: .custom
            )
        }
        
        measure {
            for _ in 0..<100 {
                _ = try? JSONEncoder().encode(testTemplates)
            }
        }
    }
    
    func testJSONDecodingPerformance() throws {
        let testTemplates = Array(0..<100).map { index in
            EmergencyTemplate(
                id: "perf-\(index)",
                name: "Performance Template \(index)",
                message: "Test message \(index) with {ADDRESS} and {GPS}",
                isActive: true,
                category: .custom
            )
        }
        
        let jsonData = try JSONEncoder().encode(testTemplates)
        
        measure {
            for _ in 0..<100 {
                _ = try? JSONDecoder().decode([EmergencyTemplate].self, from: jsonData)
            }
        }
    }
    
    // MARK: - String Processing Performance
    
    func testStringReplacementPerformance() throws {
        let template = "🚨 ALERTE - {ADDRESS} - {GPS} - {TIME} - {MAP_LINK}"
        let replacements = [
            "{ADDRESS}": "1 Rue de la Paix, 75001 Paris, France",
            "{GPS}": "48.8566°N, 2.3522°E",
            "{TIME}": "12:00:00",
            "{MAP_LINK}": "https://maps.apple.com/?q=48.8566,2.3522"
        ]
        
        measure {
            for _ in 0..<10000 {
                var result = template
                for (key, value) in replacements {
                    result = result.replacingOccurrences(of: key, with: value)
                }
                _ = result
            }
        }
    }
    
    func testStringConcatenationPerformance() throws {
        let parts = [
            "🚨 ALERTE URGENCE",
            "⚠️ J'ai besoin d'aide immédiatement !",
            "📍 Adresse: 1 Rue de la Paix, 75001 Paris, France",
            "🌐 GPS: 48.8566°N, 2.3522°E",
            "🗺️ Carte: https://maps.apple.com/?q=48.8566,2.3522",
            "⏰ Heure: 12:00:00",
            "📱 App: SafetyRing"
        ]
        
        measure {
            for _ in 0..<10000 {
                _ = parts.joined(separator: "\n\n")
            }
        }
    }
    
    // MARK: - Array Operations Performance
    
    func testArrayFilteringPerformance() throws {
        let largeArray = Array(0..<10000).map { index in
            EmergencyTemplate(
                id: "perf-\(index)",
                name: "Template \(index)",
                message: "Message \(index)",
                isActive: index % 2 == 0,
                category: .custom
            )
        }
        
        measure {
            for _ in 0..<100 {
                _ = largeArray.filter { $0.isActive }
                _ = largeArray.filter { $0.category == .custom }
                _ = largeArray.filter { $0.name.contains("Template") }
            }
        }
    }
    
    func testArrayMappingPerformance() throws {
        let largeArray = Array(0..<10000)
        
        measure {
            for _ in 0..<100 {
                _ = largeArray.map { "Template \($0)" }
                _ = largeArray.map { $0 * 2 }
                _ = largeArray.map { EmergencyTemplate(
                    id: "perf-\($0)",
                    name: "Template \($0)",
                    message: "Message \($0)",
                    isActive: true,
                    category: .custom
                ) }
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageUnderLoad() throws {
        var templates: [EmergencyTemplate] = []
        var recipients: [MessageRecipient] = []
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Créer de nombreux objets
            for i in 0..<1000 {
                let template = EmergencyTemplate(
                    id: "mem-test-\(i)",
                    name: "Memory Test Template \(i)",
                    message: "Test message \(i) with very long content to simulate real usage patterns and memory consumption",
                    isActive: true,
                    category: .custom
                )
                templates.append(template)
                
                let recipient = MessageRecipient(
                    phoneNumber: "+33123456789\(i)",
                    name: "Memory Test Recipient \(i)",
                    platforms: [.sms, .whatsapp, .telegram, .signal]
                )
                recipients.append(recipient)
            }
            
            // Effectuer des opérations
            for template in templates {
                _ = emergencyManager.generateEmergencyMessage(template: template, location: locationManager)
            }
            
            // Nettoyer
            templates.removeAll()
            recipients.removeAll()
        }
    }
    
    // MARK: - CPU Usage Tests
    
    func testCPUUsageUnderLoad() throws {
        measure(metrics: [XCTCPUMetric()]) {
            // Simuler une charge CPU élevée
            for _ in 0..<10000 {
                let mockLocation = createMockLocation()
                let template = emergencyManager.templates.first!
                _ = emergencyManager.generateEmergencyMessage(template: template, location: mockLocation)
                
                // Opérations mathématiques pour simuler la charge
                let result = sqrt(Double.random(in: 1...1000))
                _ = sin(result) * cos(result)
            }
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
            id: "perf-test",
            name: "Performance Test Template",
            message: "🚨 TEST - {ADDRESS} - {GPS} - {TIME}",
            isActive: true,
            category: .custom
        )
    }
    
    private func createMockRecipient() -> MessageRecipient {
        return MessageRecipient(
            phoneNumber: "+33123456789",
            name: "Performance Test Recipient",
            platforms: [.sms, .whatsapp]
        )
    }
}

import Foundation
import WebKit
import UIKit

struct WhatsAppWarning: Identifiable, Codable {
    let id = UUID()
    let text: String
    let severity: WarningSeverity
    let timestamp: Date
    
    enum WarningSeverity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.shield.fill"
            }
        }
    }
}

final class WhatsAppScraperManager: ObservableObject {
    @Published var isScrapingEnabled: Bool = false
    @Published var isCurrentlyScraping: Bool = false
    @Published var lastWarningShown: Date?
    @Published var usageCount: Int = 0
    @Published var lastUsed: Date?
    @Published var warnings: [WhatsAppWarning] = []
    @Published var showingDisclaimer = false
    
    private let warningsKey = "sr_whatsapp_warnings"
    private let usageKey = "sr_whatsapp_usage"
    private let enabledKey = "sr_whatsapp_enabled"
    
    init() {
        loadWarnings()
        loadUsageData()
        loadEnabledState()
        setupDefaultWarnings()
    }
    
    // MARK: - Initialization
    
    private func setupDefaultWarnings() {
        if warnings.isEmpty {
            warnings = [
                WhatsAppWarning(
                    text: "⚠️ L'utilisation du mode scraping WhatsApp peut entraîner la suspension temporaire ou permanente de votre compte WhatsApp.",
                    severity: .critical,
                    timestamp: Date()
                ),
                WhatsAppWarning(
                    text: "⚖️ Cette méthode n'est pas officiellement supportée par WhatsApp et peut violer leurs conditions d'utilisation.",
                    severity: .high,
                    timestamp: Date()
                ),
                WhatsAppWarning(
                    text: "🔒 Les fonctionnalités de scraping peuvent cesser de fonctionner à tout moment sans préavis.",
                    severity: .high,
                    timestamp: Date()
                ),
                WhatsAppWarning(
                    text: "📱 Ce mode est destiné uniquement aux situations d'urgence critiques. Utilisez-le avec parcimonie.",
                    severity: .medium,
                    timestamp: Date()
                ),
                WhatsAppWarning(
                    text: "🔄 Pour un usage quotidien et les tests, privilégiez iMessage (SMS) qui est toujours disponible et sans risque.",
                    severity: .low,
                    timestamp: Date()
                )
            ]
            saveWarnings()
        }
    }
    
    // MARK: - State Management
    
    func enableScraping() {
        isScrapingEnabled = true
        UserDefaults.standard.set(true, forKey: enabledKey)
        showDisclaimer()
    }
    
    func disableScraping() {
        isScrapingEnabled = false
        UserDefaults.standard.set(false, forKey: enabledKey)
    }
    
    func toggleScraping() {
        if isScrapingEnabled {
            disableScraping()
        } else {
            enableScraping()
        }
    }
    
    // MARK: - Disclaimer Management
    
    func showDisclaimer() {
        showingDisclaimer = true
        lastWarningShown = Date()
    }
    
    func hasSeenRecentWarning() -> Bool {
        guard let lastWarning = lastWarningShown else { return false }
        let timeSinceLastWarning = Date().timeIntervalSince(lastWarning)
        return timeSinceLastWarning < 86400 // 24 heures
    }
    
    // MARK: - Usage Tracking
    
    func incrementUsage() {
        usageCount += 1
        lastUsed = Date()
        saveUsageData()
        
        // Afficher un avertissement si l'utilisation est élevée
        if usageCount > 10 {
            addWarning(
                text: "🚨 Utilisation élevée détectée. Réduisez l'utilisation du mode WhatsApp pour éviter les risques de bannissement.",
                severity: .high
            )
        }
    }
    
    func resetUsage() {
        usageCount = 0
        lastUsed = nil
        saveUsageData()
    }
    
    // MARK: - Warning Management
    
    func addWarning(_ text: String, severity: WhatsAppWarning.WarningSeverity) {
        let warning = WhatsAppWarning(text: text, severity: severity, timestamp: Date())
        warnings.append(warning)
        saveWarnings()
        
        // Limiter le nombre d'avertissements
        if warnings.count > 20 {
            warnings.removeFirst(warnings.count - 20)
            saveWarnings()
        }
    }
    
    func removeWarning(_ warning: WhatsAppWarning) {
        warnings.removeAll { $0.id == warning.id }
        saveWarnings()
    }
    
    func clearWarnings() {
        warnings.removeAll()
        saveWarnings()
    }
    
    // MARK: - Scraping Functions
    
    func sendMessage(to phoneNumber: String, message: String) async -> Bool {
        guard isScrapingEnabled else {
            print("WhatsApp scraping is disabled")
            return false
        }
        
        // Vérifier si l'utilisateur a vu l'avertissement récemment
        if !hasSeenRecentWarning() {
            await MainActor.run {
                showDisclaimer()
            }
            return false
        }
        
        // Simuler l'envoi de message
        await MainActor.run {
            isCurrentlyScraping = true
        }
        
        // Simuler un délai d'envoi
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
        
        await MainActor.run {
            isCurrentlyScraping = false
            incrementUsage()
        }
        
        // Pour l'instant, on simule un succès
        // Dans une vraie implémentation, on utiliserait WKWebView pour le scraping
        print("Message WhatsApp simulé envoyé à \(phoneNumber): \(message)")
        return true
    }
    
    // MARK: - Data Persistence
    
    private func saveWarnings() {
        if let data = try? JSONEncoder().encode(warnings) {
            UserDefaults.standard.set(data, forKey: warningsKey)
        }
    }
    
    private func loadWarnings() {
        if let data = UserDefaults.standard.data(forKey: warningsKey),
           let loadedWarnings = try? JSONDecoder().decode([WhatsAppWarning].self, from: data) {
            warnings = loadedWarnings
        }
    }
    
    private func saveUsageData() {
        UserDefaults.standard.set(usageCount, forKey: "\(usageKey)_count")
        if let lastUsed = lastUsed {
            UserDefaults.standard.set(lastUsed, forKey: "\(usageKey)_last")
        }
    }
    
    private func loadUsageData() {
        usageCount = UserDefaults.standard.integer(forKey: "\(usageKey)_count")
        lastUsed = UserDefaults.standard.object(forKey: "\(usageKey)_last") as? Date
    }
    
    private func saveEnabledState() {
        UserDefaults.standard.set(isScrapingEnabled, forKey: enabledKey)
    }
    
    private func loadEnabledState() {
        isScrapingEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }
    
    // MARK: - Statistics
    
    func getUsageStatistics() -> [String: Any] {
        return [
            "totalUsage": usageCount,
            "lastUsed": lastUsed?.timeIntervalSince1970 ?? 0,
            "isEnabled": isScrapingEnabled,
            "warningsCount": warnings.count,
            "criticalWarnings": warnings.filter { $0.severity == .critical }.count,
            "highWarnings": warnings.filter { $0.severity == .high }.count,
            "mediumWarnings": warnings.filter { $0.severity == .medium }.count,
            "lowWarnings": warnings.filter { $0.severity == .low }.count
        ]
    }
    
    // MARK: - Risk Assessment
    
    func getRiskLevel() -> String {
        if usageCount > 20 {
            return "Élevé"
        } else if usageCount > 10 {
            return "Modéré"
        } else if usageCount > 5 {
            return "Faible"
        } else {
            return "Minimal"
        }
    }
    
    func getRiskDescription() -> String {
        switch getRiskLevel() {
        case "Élevé":
            return "Risque élevé de bannissement. Arrêtez immédiatement l'utilisation du mode WhatsApp."
        case "Modéré":
            return "Risque modéré. Réduisez l'utilisation et privilégiez iMessage."
        case "Faible":
            return "Risque faible. Continuez à utiliser avec précaution."
        default:
            return "Risque minimal. Utilisation normale autorisée."
        }
    }
    
    // MARK: - Recommendations
    
    func getRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if usageCount > 15 {
            recommendations.append("🚨 Arrêtez immédiatement l'utilisation du mode WhatsApp")
            recommendations.append("📱 Utilisez exclusivement iMessage pour les alertes")
            recommendations.append("⏰ Attendez au moins 24h avant de réessayer")
        } else if usageCount > 10 {
            recommendations.append("⚠️ Réduisez drastiquement l'utilisation du mode WhatsApp")
            recommendations.append("📱 Privilégiez iMessage pour les tests")
            recommendations.append("🔄 Espacez les utilisations de plusieurs heures")
        } else if usageCount > 5 {
            recommendations.append("📝 Limitez l'utilisation aux vraies urgences")
            recommendations.append("🧪 Utilisez iMessage pour les tests")
            recommendations.append("⏱️ Espacez les utilisations")
        } else {
            recommendations.append("✅ Utilisation normale autorisée")
            recommendations.append("📱 Continuez à privilégier iMessage")
            recommendations.append("⚠️ Restez vigilant aux changements")
        }
        
        return recommendations
    }
    
    // MARK: - Reset Functions
    
    func resetAllData() {
        warnings.removeAll()
        usageCount = 0
        lastUsed = nil
        isScrapingEnabled = false
        lastWarningShown = nil
        
        saveWarnings()
        saveUsageData()
        saveEnabledState()
    }
    
    func softReset() {
        // Reset partiel - garde les avertissements mais reset l'utilisation
        usageCount = 0
        lastUsed = nil
        saveUsageData()
    }
}

// MARK: - Extensions

extension WhatsAppWarning.WarningSeverity: Identifiable {
    var id: String { rawValue }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AlertSettingsManager
    @EnvironmentObject var emergencyManager: EmergencyMessageManager
    @EnvironmentObject var multiPlatformManager: MultiPlatformMessageManager
    @StateObject private var whatsAppScraper = WhatsAppScraperManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingScrapingDisclaimer = false
    @State private var showingScrapingSettings = false
    @State private var showingUsageGuidelines = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Alertes") {
                    Toggle("Vibration", isOn: $settings.settings.enableVibration)
                    Toggle("Son d'alerte", isOn: $settings.settings.enableSound)
                    Toggle("SMS automatique", isOn: $settings.settings.autoSendSMS)
                    
                    HStack {
                        Text("Durée vibration")
                        Spacer()
                        Text("\(Int(settings.settings.vibrationDuration))s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.settings.vibrationDuration, in: 1...10, step: 0.5)
                }
                
                Section("Plateformes de messages") {
                    Toggle("Messages multi-plateformes", isOn: $settings.settings.enableMultiPlatform)
                    if settings.settings.enableMultiPlatform {
                        Picker("Plateforme préférée", selection: $settings.settings.preferredPlatform) {
                            ForEach(MessagePlatform.allCases) { platform in
                                Text(platform.rawValue).tag(platform)
                            }
                        }
                    }
                }
                
                Section("🚨 Mode Urgence Critique - WhatsApp") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("WhatsApp Scraping")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text("Envoi automatique sans confirmation (RISQUÉ)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Statut:")
                            Spacer()
                            Text(whatsAppScraper.getScrapingStatus())
                                .font(.caption)
                                .foregroundColor(whatsAppScraper.isScrapingEnabled ? .green : .secondary)
                        }
                        
                        HStack {
                            Button("Afficher les risques") {
                                showingScrapingDisclaimer = true
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Guide d'usage") {
                                showingUsageGuidelines = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if whatsAppScraper.isScrapingEnabled {
                            Button("DÉSACTIVER LE MODE SCRAPING") {
                                whatsAppScraper.disableScrapingMode()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                        } else {
                            Button("ACTIVER LE MODE SCRAPING") {
                                showingScrapingDisclaimer = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Templates d'urgence") {
                    ForEach(emergencyManager.templates) { template in
                        Toggle(template.name, isOn: Binding(
                            get: { template.isActive },
                            set: { newValue in
                                var updatedTemplate = template
                                updatedTemplate.isActive = newValue
                                emergencyManager.updateTemplate(updatedTemplate)
                            }
                        ))
                    }
                }
                
                Section("Message personnalisé") {
                    TextEditor(text: Binding(
                        get: { emergencyManager.customMessage },
                        set: { emergencyManager.updateCustomMessage($0) }
                    ))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("Variables disponibles: {ADDRESS}, {GPS}, {MAP_LINK}, {TIME}")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingScrapingDisclaimer) {
            ScrapingDisclaimerView(whatsAppScraper: whatsAppScraper)
        }
        .sheet(isPresented: $showingUsageGuidelines) {
            UsageGuidelinesView()
        }
    }
}

// MARK: - Scraping Disclaimer View

struct ScrapingDisclaimerView: View {
    @ObservedObject var whatsAppScraper: WhatsAppScraperManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("ATTENTION - RISQUES MAJEURS")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Disclaimer Text
                    Text(whatsAppScraper.showScrapingDisclaimer())
                        .font(.body)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                    
                    // Warnings List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚠️ AVERTISSEMENTS SPÉCIFIQUES")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        ForEach(whatsAppScraper.scrapingWarnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text(warning)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button("J'ACCEPTE LES RISQUES - ACTIVER") {
                            whatsAppScraper.enableScrapingMode()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)
                        
                        Button("ANNULER - NE PAS ACTIVER") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Avertissement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Usage Guidelines View

struct UsageGuidelinesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Guide d'Utilisation Responsable")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Guidelines Text
                    Text(WhatsAppScraperManager.usageGuidelines)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                    
                    // Additional Safety Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔐 CONSEILS DE SÉCURITÉ SUPPLÉMENTAIRES")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Créez un compte WhatsApp dédié aux urgences")
                            Text("• Utilisez un numéro de téléphone secondaire")
                            Text("• Testez d'abord avec des numéros de test")
                            Text("• Gardez un journal des utilisations")
                            Text("• Préparez des alternatives (SMS, appel)")
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 20)
                    
                    // Close Button
                    Button("J'ai compris") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Guide d'Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

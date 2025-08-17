import SwiftUI
import CoreBluetooth
import CoreLocation
import MessageUI
import AVFoundation

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var reachability = ReachabilityMonitor()
    @StateObject private var store = AlertStore()
    @StateObject private var alertHandler = AlertHandler()
    @StateObject private var loc = LocationManager()
    @StateObject private var settings = AlertSettingsManager()
    @StateObject private var emergencyManager = EmergencyMessageManager()
    @StateObject private var multiPlatformManager = MultiPlatformMessageManager()
    @StateObject private var whatsAppScraper = WhatsAppScraperManager()
    
    @State private var showingMessageCompose = false
    @State private var showingEmergencyTemplateSelector = false
    @State private var showingRecipientEditor = false
    @StateObject private var messageComposer = MessageComposer()
    
    @State private var isAlertActive = false
    @State private var alertCountdown = 5
    @State private var alertTimer: Timer?
    
    var body: some View {
        Group {
            if !multiPlatformManager.hasUserConsent {
                // Vue de consentement au premier lancement
                ConsentView(multiPlatformManager: multiPlatformManager)
            } else {
                // Interface principale de l'application
                mainInterface
            }
        }
    }
    
    private var mainInterface: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("SafetyRing")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Système d'alerte d'urgence intelligent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Status Cards
                        VStack(spacing: 15) {
                            StatusCard(
                                title: "Bluetooth",
                                status: bleManager.isConnected ? "Connecté" : "Déconnecté",
                                icon: bleManager.isConnected ? "bluetooth" : "bluetooth.slash",
                                color: bleManager.isConnected ? .green : .red
                            )
                            
                            StatusCard(
                                title: "Réseau",
                                status: reachability.isConnected ? "Connecté" : "Hors ligne",
                                icon: reachability.isConnected ? "wifi" : "wifi.slash",
                                color: reachability.isConnected ? .green : .orange
                            )
                            
                            StatusCard(
                                title: "Localisation",
                                status: loc.isLocationEnabled ? "Active" : "Inactive",
                                icon: loc.isLocationEnabled ? "location.fill" : "location.slash",
                                color: loc.isLocationEnabled ? .green : .red
                            )
                        }
                        
                        // Emergency Alert Button
                        VStack(spacing: 15) {
                            Button(action: {
                                if !isAlertActive {
                                    triggerEmergencyAlert()
                                }
                            }) {
                                HStack {
                                    Image(systemName: isAlertActive ? "stop.circle.fill" : "exclamationmark.triangle.fill")
                                        .font(.title2)
                                    Text(isAlertActive ? "Annuler l'alerte" : "🚨 ALERTE D'URGENCE")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isAlertActive ?
                                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            }
                            .disabled(isAlertActive)
                            
                            if isAlertActive {
                                VStack(spacing: 8) {
                                    Text("Alerte active - \(alertCountdown)s restantes")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    ProgressView(value: Double(5 - alertCountdown), total: 5)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Emergency Templates Section
                        emergencyTemplatesSection
                        
                        // Recipients Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("📱 Destinataires")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("Ajouter") {
                                    showingRecipientEditor = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if multiPlatformManager.recipients.isEmpty {
                                Text("Aucun destinataire configuré")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(multiPlatformManager.recipients.filter { $0.isActive }) { recipient in
                                    RecipientRow(recipient: recipient) {
                                        // Action when tapped
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        
                        // Alert Logs Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("📋 Historique des alertes")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if store.alertLogs.isEmpty {
                                Text("Aucune alerte enregistrée")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(store.alertLogs.prefix(5)) { log in
                                    AlertLogRow(log: log)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        
                        // Settings Button
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Paramètres")
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loc.requestPermission()
                loc.startUpdatingLocation()
            }
        }
        .sheet(isPresented: $showingMessageCompose) {
            MessageComposeView(
                recipients: multiPlatformManager.recipients.filter { $0.isActive }.map { $0.phoneNumber },
                body: loc.getEmergencyLocationText()
            )
        }
        .sheet(isPresented: $showingEmergencyTemplateSelector) {
            EmergencyTemplateSelectorView(emergencyManager: emergencyManager)
        }
        .sheet(isPresented: $showingRecipientEditor) {
            RecipientEditorView(multiPlatformManager: multiPlatformManager)
        }
        .onReceive(bleManager.$lastAlertData) { alertData in
            if let data = alertData, data == "ALERT" {
                triggerEmergencyAlert()
            }
        }
    }
    
    // MARK: - Emergency Alert Functions
    
    private func triggerEmergencyAlert() {
        guard !isAlertActive else { return }
        
        isAlertActive = true
        alertCountdown = 5
        
        // Déclencher l'alerte locale immédiatement
        alertHandler.triggerLocalAlert()
        
        // Démarrer le compte à rebours
        alertTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if alertCountdown > 0 {
                alertCountdown -= 1
                
                // Vibration continue pendant le compte à rebours
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
            } else {
                // Temps écoulé - envoyer le message
                sendEmergencyMessage()
                stopAlert()
            }
        }
    }
    
    private func stopAlert() {
        isAlertActive = false
        alertCountdown = 0
        alertTimer?.invalidate()
        alertTimer = nil
        
        // Arrêter le son d'alerte
        alertHandler.stopAlertSound()
    }
    
    private func sendEmergencyMessage() {
        // Jouer le son d'alerte dissuasif
        alertHandler.playAlertSound("alert")
        
        // Envoyer le message selon la plateforme préférée
        let platform = settings.settings.preferredPlatform
        let message = emergencyManager.generateCustomMessage(location: loc)
        
        // Mode multi-plateforme simplifié (iMessage + WhatsApp)
        let activeRecipients = multiPlatformManager.recipients.filter { $0.isActive }
        
        for recipient in activeRecipients {
            // Essayer d'abord la plateforme préférée du destinataire
            let preferredPlatform = recipient.platforms.first ?? .imessage
            
            if preferredPlatform == .whatsapp && whatsAppScraper.isScrapingEnabled {
                // Utiliser WhatsApp avec scraping
                _ = multiPlatformManager.sendEmergencyMessage(
                    to: recipient,
                    message: message,
                    platform: .whatsapp,
                    useScraping: true
                )
            } else {
                // Utiliser iMessage par défaut
                _ = multiPlatformManager.sendEmergencyMessage(
                    to: recipient,
                    message: message,
                    platform: .imessage,
                    useScraping: false
                )
            }
        }
        
        // Enregistrer l'alerte
        store.addAlertLog(
            AlertLog(
                timestamp: Date(),
                message: message,
                location: loc.getFormattedLocation(),
                wasSent: true
            )
        )
        
        // Haptic feedback de succès
        let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
        hapticFeedback.impactOccurred()
    }
    
    private func triggerEmergencyAlert(with template: EmergencyTemplate) {
        guard !isAlertActive else { return }
        
        isAlertActive = true
        alertCountdown = 5
        
        // Déclencher l'alerte locale immédiatement
        alertHandler.triggerLocalAlert()
        
        // Démarrer le compte à rebours
        alertTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if alertCountdown > 0 {
                alertCountdown -= 1
                
                // Vibration continue pendant le compte à rebours
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
            } else {
                // Temps écoulé - envoyer le message avec le template
                sendEmergencyMessageWithTemplate(template)
                stopAlert()
            }
        }
    }
    
    private func sendEmergencyMessageWithTemplate(_ template: EmergencyTemplate) {
        // Jouer le son d'alerte dissuasif
        alertHandler.playAlertSound("alert")
        
        // Générer le message avec le template
        let message = emergencyManager.generateEmergencyMessage(template: template, location: loc)
        
        // Envoyer selon les plateformes des destinataires
        let activeRecipients = multiPlatformManager.recipients.filter { $0.isActive }
        
        for recipient in activeRecipients {
            // Essayer d'abord la plateforme préférée du destinataire
            let preferredPlatform = recipient.platforms.first ?? .imessage
            
            if preferredPlatform == .whatsapp && whatsAppScraper.isScrapingEnabled {
                // Utiliser WhatsApp avec scraping
                _ = multiPlatformManager.sendEmergencyMessage(
                    to: recipient,
                    message: message,
                    platform: .whatsapp,
                    useScraping: true
                )
            } else {
                // Utiliser iMessage par défaut
                _ = multiPlatformManager.sendEmergencyMessage(
                    to: recipient,
                    message: message,
                    platform: .imessage,
                    useScraping: false
                )
            }
        }
        
        // Enregistrer l'alerte
        store.addAlertLog(
            AlertLog(
                timestamp: Date(),
                message: message,
                location: loc.getFormattedLocation(),
                wasSent: true
            )
        )
        
        // Haptic feedback de succès
        let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
        hapticFeedback.impactOccurred()
    }
    
    // MARK: - UI Sections
    
    private var emergencyTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("🚨 Templates d'urgence")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Sélectionner") {
                    showingEmergencyTemplateSelector = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(emergencyManager.templates.filter { $0.isActive }) { template in
                    EmergencyTemplateCard(template: template) {
                        triggerEmergencyAlert(with: template)
                    }
                }
            }
            
            if emergencyManager.templates.filter({ $0.isActive }).isEmpty {
                Text("Aucun template d'urgence actif")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views (StatusCard, RecipientRow, AlertLogRow, EmergencyTemplateCard, MessageComposer, MessageComposeView)

struct StatusCard: View {
    let title: String
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(status)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecipientRow: View {
    let recipient: MessageRecipient
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipient.name)
                    .font(.headline)
                Text(recipient.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(recipient.platforms, id: \.self) { platform in
                    Image(systemName: platform.icon)
                        .foregroundColor(Color(platform.color))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onTapGesture {
            action()
        }
    }
}

struct AlertLogRow: View {
    let log: AlertLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: log.wasSent ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(log.wasSent ? .green : .red)
            }
            
            Text(log.message)
                .font(.body)
                .lineLimit(2)
            
            if !log.location.isEmpty {
                Text("📍 \(log.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmergencyTemplateCard: View {
    let template: EmergencyTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.category.icon)
                        .foregroundColor(template.category.color)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                Text(template.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Message Composer

class MessageComposer: NSObject, ObservableObject {
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settings: AlertSettingsManager
    @EnvironmentObject var emergencyManager: EmergencyMessageManager
    @EnvironmentObject var multiPlatformManager: MultiPlatformMessageManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
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
    }
}

// MARK: - Alert Settings Manager

class AlertSettingsManager: ObservableObject {
    @Published var settings: AlertSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let settingsKey = "sr_alert_settings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(AlertSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = AlertSettings()
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
}

extension AlertSettings: Codable {}



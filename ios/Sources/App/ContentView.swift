import SwiftUI
import MessageUI
import UIKit

struct AlertSettings {
    var enableVibration: Bool = true
    var enableSound: Bool = true
    var vibrationDuration: Double = 5.0
    var autoSendSMS: Bool = true
    var alertSound: String = "default"
}

struct ContentView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var loc: LocationManager
    @EnvironmentObject var net: ReachabilityMonitor
    @EnvironmentObject var store: AlertStore
    @EnvironmentObject var alerts: AlertHandler
    @EnvironmentObject var settings: AlertSettingsManager

    @State private var newRecipient: String = ""
    @State private var showingComposer: Bool = false
    @State private var composerBody: String = ""
    @State private var showingSettings: Bool = false
    @State private var isAlertActive: Bool = false
    @State private var alertCountdown: Double = 5.0
    @State private var alertTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Status Cards
                        statusSection
                        
                        // Alert Control
                        alertControlSection
                        
                        // Recipients
                        recipientsSection
                        
                        // Alert Logs
                        alertLogsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("SafetyRing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingComposer) {
            MessageComposeView(recipients: store.recipients, body: composerBody) { sent in
                if sent {
                    store.appendLog(title: "SMS envoyé")
                } else {
                    store.appendLog(title: "SMS annulé")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .onReceive(alerts.alertPublisher) { _ in
            triggerAlert()
        }
        .onChange(of: net.isOnline) { isOnline in
            if isOnline, store.hasPendingAlerts {
                presentComposerForPending()
            }
        }
        .onReceive(ble.$isConnected) { connected in
            if connected {
                hapticFeedback(.medium)
            }
        }
    }

    // MARK: - UI Components
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            // BLE Status
            StatusCard(
                title: "Connexion BLE",
                status: ble.isConnected ? .connected : (ble.isScanning ? .scanning : .disconnected),
                icon: "wave.3.right",
                action: {
                    if ble.isConnected {
                        ble.restartScan()
                    } else if !ble.isScanning {
                        ble.restartScan()
                    }
                }
            )
            
            // Network Status
            StatusCard(
                title: "Connexion réseau",
                status: net.isOnline ? .connected : .disconnected,
                icon: "wifi",
                action: nil
            )
        }
    }
    
    private var alertControlSection: some View {
        VStack(spacing: 16) {
            if isAlertActive {
                // Active Alert Countdown
                VStack(spacing: 12) {
                    Text("ALERTE ACTIVE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Annulation possible pendant \(Int(alertCountdown))s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: alertCountdown, total: 5.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .scaleEffect(x: 1.2, y: 1.2)
                    
                    Button("ANNULER L'ALERTE") {
                        cancelAlert()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        )
                )
            } else {
                // Manual Alert Button
                Button(action: triggerAlert) {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("DÉCLENCHER ALERTE")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
    }
    
    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                Text("Destinataires SMS")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack {
                TextField("+33612345678", text: $newRecipient)
                    .keyboardType(.phonePad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                
                Button("Ajouter") {
                    addRecipient()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if !store.recipients.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(store.recipients, id: \.self) { num in
                        RecipientRow(phoneNumber: num) {
                            store.removeRecipient(num)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Aucun destinataire configuré")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var alertLogsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.purple)
                Text("Journal des alertes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if !store.logs.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(store.logs.prefix(5)) { log in
                        AlertLogRow(log: log)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Aucune alerte enregistrée")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Alert Logic
    
    private func triggerAlert() {
        guard !isAlertActive else { return }
        
        isAlertActive = true
        alertCountdown = 5.0
        
        // Start vibration and countdown
        if settings.settings.enableVibration {
            startVibration()
        }
        
        // Start countdown timer
        alertTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if alertCountdown > 0 {
                alertCountdown -= 0.1
            } else {
                executeAlert()
            }
        }
    }
    
    private func cancelAlert() {
        isAlertActive = false
        alertTimer?.invalidate()
        alertTimer = nil
        stopVibration()
        
        hapticFeedback(.medium)
        store.appendLog(title: "Alerte annulée par l'utilisateur")
    }
    
    private func executeAlert() {
        isAlertActive = false
        alertTimer?.invalidate()
        alertTimer = nil
        stopVibration()
        
        alerts.triggerLocalAlert()
        
        let coords = loc.lastCoordinate
        let locationText: String
        if let c = coords {
            let url = "https://maps.apple.com/?ll=\(c.latitude),\(c.longitude)"
            locationText = "Localisation : \(url)"
        } else {
            locationText = "Localisation : inconnue"
        }
        let body = "🚨 ALERTE : J'ai besoin d'aide ! \n📍 \(locationText)"

        if net.isOnline && MFMessageComposeViewController.canSendText() && !store.recipients.isEmpty {
            if settings.settings.autoSendSMS {
                composerBody = body
                showingComposer = true
                store.appendLog(title: "SMS automatique préparé")
            } else {
                store.appendLog(title: "Alerte déclenchée (SMS manuel)")
            }
        } else {
            store.appendPendingAlert(body: body)
            store.appendLog(title: "Alerte stockée (hors-ligne)")
        }
    }
    
    private func startVibration() {
        // Continuous vibration for 5 seconds
        DispatchQueue.global(qos: .userInteractive).async {
            for _ in 0..<50 { // 5 seconds with 0.1s intervals
                DispatchQueue.main.async {
                    hapticFeedback(.heavy)
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    private func stopVibration() {
        // Stop vibration
        hapticFeedback(.light)
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }

    private func addRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addRecipient(trimmed)
        newRecipient = ""
        hapticFeedback(.light)
    }

    private func presentComposerForPending() {
        guard let pending = store.popNextPendingAlert() else { return }
        if MFMessageComposeViewController.canSendText() && !store.recipients.isEmpty {
            composerBody = pending.body
            showingComposer = true
        } else {
            store.appendLog(title: "Impossible de composer le SMS")
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let status: ConnectionStatus
    let icon: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(status.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(status.actionText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(status.color.opacity(0.2))
                        .foregroundColor(status.color)
                        .clipShape(Capsule())
                }
                .disabled(status == .scanning)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}

struct RecipientRow: View {
    let phoneNumber: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "phone.fill")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(phoneNumber)
                .font(.subheadline)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AlertLogRow: View {
    let log: AlertLog
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.purple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(log.timestamp.formatted(date: .numeric, time: .standard))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

enum ConnectionStatus {
    case connected, scanning, disconnected
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .scanning: return .orange
        case .disconnected: return .red
        }
    }
    
    var description: String {
        switch self {
        case .connected: return "Connecté"
        case .scanning: return "Scan en cours..."
        case .disconnected: return "Non connecté"
        }
    }
    
    var actionText: String {
        switch self {
        case .connected: return "Reconnecter"
        case .scanning: return "Scanning..."
        case .disconnected: return "Scanner"
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    var completion: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (Bool) -> Void
        init(completion: @escaping (Bool) -> Void) { self.completion = completion }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) {
                self.completion(result == .sent)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settings: AlertSettingsManager
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
                
                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
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



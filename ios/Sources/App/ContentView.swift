import SwiftUI
import MessageUI

struct ContentView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var loc: LocationManager
    @EnvironmentObject var net: ReachabilityMonitor
    @EnvironmentObject var store: AlertStore
    @EnvironmentObject var alerts: AlertHandler

    @State private var newRecipient: String = ""
    @State private var showingComposer: Bool = false
    @State private var composerBody: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    HStack {
                        Circle()
                            .fill(ble.isConnected ? Color.green : (ble.isScanning ? Color.orange : Color.red))
                            .frame(width: 12, height: 12)
                        Text(bleStatusText)
                        Spacer()
                        Button(ble.isConnected ? "Reconnect" : (ble.isScanning ? "Scanning…" : "Scan")) {
                            ble.restartScan()
                        }
                        .disabled(ble.isScanning)
                    }

                    HStack {
                        Circle()
                            .fill(net.isOnline ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(net.isOnline ? "Online" : "Offline")
                    }
                }

                Group {
                    Text("Destinataires (SMS)").font(.headline)
                    HStack {
                        TextField("+33612345678", text: $newRecipient)
                            .keyboardType(.phonePad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Ajouter") {
                            addRecipient()
                        }
                    }
                    ForEach(store.recipients, id: \.self) { num in
                        HStack {
                            Text(num)
                            Spacer()
                            Button(role: .destructive) {
                                store.removeRecipient(num)
                            } label: { Image(systemName: "trash") }
                        }
                    }
                }

                Divider()
                Text("Journal des alertes").font(.headline)
                List(store.logs) { log in
                    VStack(alignment: .leading) {
                        Text(log.title)
                        Text(log.timestamp.formatted(date: .numeric, time: .standard))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Simuler alerte") {
                    triggerAlert()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("SafetyRing")
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
        .onReceive(alerts.alertPublisher) { _ in
            triggerAlert()
        }
        .onChange(of: net.isOnline) { isOnline in
            if isOnline, store.hasPendingAlerts {
                presentComposerForPending()
            }
        }
    }

    private var bleStatusText: String {
        if ble.isConnected { return "Connecté à SafetyRing" }
        if ble.isScanning { return "Scan en cours…" }
        return "Non connecté"
    }

    private func addRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addRecipient(trimmed)
        newRecipient = ""
    }

    private func triggerAlert() {
        alerts.triggerLocalAlert()
        let coords = loc.lastCoordinate
        let locationText: String
        if let c = coords {
            let url = "https://maps.apple.com/?ll=\(c.latitude),\(c.longitude)"
            locationText = "Localisation : \(url)"
        } else {
            locationText = "Localisation : inconnue"
        }
        let body = "Alerte : j’ai besoin d’aide ! \n\(locationText)"

        if net.isOnline && MFMessageComposeViewController.canSendText() && !store.recipients.isEmpty {
            composerBody = body
            showingComposer = true
            store.appendLog(title: "Proposition d’envoi de SMS")
        } else {
            store.appendPendingAlert(body: body)
            store.appendLog(title: "Alerte stockée (hors-ligne)" )
        }
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



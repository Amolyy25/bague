import SwiftUI

struct ConsentView: View {
    @ObservedObject var multiPlatformManager: MultiPlatformMessageManager
    @State private var showingWhatsAppDisclaimer = false
    @State private var hasAcceptedWhatsApp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("SafetyRing")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Système d'alerte d'urgence intelligent")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Description
                    VStack(spacing: 20) {
                        Text("Bienvenue dans SafetyRing")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Cette application vous permet de déclencher rapidement des alertes d'urgence et d'envoyer automatiquement des messages de détresse à vos contacts configurés.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            FeatureRow(icon: "location.fill", title: "Géolocalisation", description: "Votre position sera incluse dans les messages d'urgence")
                            FeatureRow(icon: "message.fill", title: "Messages automatiques", description: "Envoi automatique via iMessage et WhatsApp")
                            FeatureRow(icon: "bluetooth", title: "Connexion BLE", description: "Déclenchement automatique depuis votre bague SafetyRing")
                            FeatureRow(icon: "bell.fill", title: "Alertes intelligentes", description: "Système de compte à rebours et vibrations de confirmation")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // WhatsApp Disclaimer
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            Text("Mode WhatsApp d'urgence")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text("SafetyRing peut utiliser WhatsApp pour envoyer des messages d'urgence automatiquement. Cette fonctionnalité est expérimentale et peut présenter des risques.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Lire les avertissements") {
                            showingWhatsAppDisclaimer = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                        
                        Toggle("J'accepte d'utiliser le mode WhatsApp d'urgence", isOn: $hasAcceptedWhatsApp)
                            .font(.body)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(15)
                    
                    // Consent Buttons
                    VStack(spacing: 20) {
                        Button(action: {
                            multiPlatformManager.setUserConsent(true)
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("J'accepte et je comprends")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .disabled(!hasAcceptedWhatsApp)
                        
                        Button(action: {
                            // L'utilisateur refuse - on peut afficher un message ou quitter
                            exit(0)
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Je refuse")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Legal Notice
                    VStack(spacing: 10) {
                        Text("En utilisant cette application, vous acceptez que :")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            LegalRow(text: "• Votre position GPS sera partagée en cas d'urgence")
                            LegalRow(text: "• Des messages automatiques seront envoyés à vos contacts")
                            LegalRow(text: "• L'application peut utiliser WhatsApp de manière expérimentale")
                            LegalRow(text: "• Vous êtes responsable de l'utilisation de cette application")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
        .sheet(isPresented: $showingWhatsAppDisclaimer) {
            WhatsAppDisclaimerView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LegalRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

struct WhatsAppDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("⚠️ Avertissements WhatsApp")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Mode d'urgence critique - Utilisation expérimentale")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    .padding(.top)
                    
                    // Warnings
                    VStack(spacing: 20) {
                        WarningSection(
                            title: "🚨 Risques de Bannissement",
                            description: "L'utilisation du mode scraping WhatsApp peut entraîner la suspension temporaire ou permanente de votre compte WhatsApp.",
                            icon: "xmark.shield.fill",
                            color: .red
                        )
                        
                        WarningSection(
                            title: "⚖️ Violation des Conditions",
                            description: "Cette méthode n'est pas officiellement supportée par WhatsApp et peut violer leurs conditions d'utilisation.",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        WarningSection(
                            title: "🔒 Instabilité des Fonctionnalités",
                            description: "Les fonctionnalités de scraping peuvent cesser de fonctionner à tout moment sans préavis.",
                            icon: "wifi.slash",
                            color: .yellow
                        )
                        
                        WarningSection(
                            title: "📱 Utilisation Responsable",
                            description: "Ce mode est destiné uniquement aux situations d'urgence critiques. Utilisez-le avec parcimonie.",
                            icon: "hand.raised.fill",
                            color: .blue
                        )
                    }
                    
                    // Guidelines
                    VStack(spacing: 15) {
                        Text("📋 Guidelines d'Utilisation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            GuidelineRow(text: "• Utilisez uniquement en cas d'urgence réelle")
                            GuidelineRow(text: "• Évitez les tests répétés")
                            GuidelineRow(text: "• Privilégiez iMessage pour les tests")
                            GuidelineRow(text: "• Surveillez votre compte WhatsApp")
                            GuidelineRow(text: "• Ayez un plan de secours (SMS)")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    }
                    
                    // Alternative
                    VStack(spacing: 15) {
                        Text("🔄 Alternative Recommandée")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Pour un usage quotidien et les tests, utilisez iMessage (SMS) qui est toujours disponible et sans risque.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(15)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Avertissements WhatsApp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compris") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct WarningSection: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

#Preview {
    ConsentView(multiPlatformManager: MultiPlatformMessageManager())
}

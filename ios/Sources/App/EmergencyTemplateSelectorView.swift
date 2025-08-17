import SwiftUI

struct EmergencyTemplateSelectorView: View {
    @ObservedObject var emergencyManager: EmergencyMessageManager
    let onTemplateSelected: (EmergencyTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Templates prédéfinis") {
                    ForEach(emergencyManager.templates) { template in
                        EmergencyTemplateRow(template: template) {
                            onTemplateSelected(template)
                            dismiss()
                        }
                    }
                }
                
                Section("Template personnalisé") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message personnalisé")
                            .font(.headline)
                        
                        Text("Utilisez les variables suivantes :")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• {ADDRESS} - Adresse complète")
                            Text("• {GPS} - Coordonnées GPS")
                            Text("• {MAP_LINK} - Lien vers la carte")
                            Text("• {TIME} - Heure de l'alerte")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Button("Utiliser message personnalisé") {
                            let customTemplate = EmergencyTemplate(
                                name: "Personnalisé",
                                message: emergencyManager.customMessage.isEmpty ? 
                                    "🚨 ALERTE URGENCE\n⚠️ J'ai besoin d'aide !\n📍 {ADDRESS}\n🌐 {GPS}\n🗺️ {MAP_LINK}\n⏰ {TIME}" :
                                    emergencyManager.customMessage,
                                isActive: true,
                                category: .custom,
                                customVariables: [:]
                            )
                            onTemplateSelected(customTemplate)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Sélectionner template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmergencyTemplateRow: View {
    let template: EmergencyTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: template.category.icon)
                    .foregroundColor(Color(template.category.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

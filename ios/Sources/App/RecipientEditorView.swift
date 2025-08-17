import SwiftUI

struct RecipientEditorView: View {
    @ObservedObject var multiPlatformManager: MultiPlatformMessageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPhoneNumber = ""
    @State private var newName = ""
    @State private var selectedPlatforms: Set<MessagePlatform> = [.sms]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Ajouter un destinataire") {
                    VStack(spacing: 12) {
                        TextField("Nom (optionnel)", text: $newName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Numéro de téléphone", text: $newPhoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plateformes supportées")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(MessagePlatform.allCases) { platform in
                                    PlatformToggleButton(
                                        platform: platform,
                                        isSelected: selectedPlatforms.contains(platform)
                                    ) {
                                        if selectedPlatforms.contains(platform) {
                                            selectedPlatforms.remove(platform)
                                        } else {
                                            selectedPlatforms.insert(platform)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button("Ajouter") {
                            addRecipient()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(newPhoneNumber.isEmpty || selectedPlatforms.isEmpty)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Destinataires existants") {
                    if multiPlatformManager.recipients.isEmpty {
                        Text("Aucun destinataire configuré")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(multiPlatformManager.recipients) { recipient in
                            RecipientDetailRow(recipient: recipient) { updatedRecipient in
                                multiPlatformManager.updateRecipient(updatedRecipient)
                            } onDelete: {
                                multiPlatformManager.removeRecipient(recipient)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gérer destinataires")
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
    
    private func addRecipient() {
        let trimmedPhone = newPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedPhone.isEmpty else { return }
        
        let recipient = MessageRecipient(
            phoneNumber: trimmedPhone,
            name: trimmedName.isEmpty ? trimmedPhone : trimmedName,
            platforms: Array(selectedPlatforms)
        )
        
        multiPlatformManager.addRecipient(recipient)
        
        // Reset form
        newPhoneNumber = ""
        newName = ""
        selectedPlatforms = [.sms]
    }
}

struct PlatformToggleButton: View {
    let platform: MessagePlatform
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.caption)
                
                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(platform.color).opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? Color(platform.color) : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(platform.color) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecipientDetailRow: View {
    let recipient: MessageRecipient
    let onUpdate: (MessageRecipient) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedPlatforms: Set<MessagePlatform>
    
    init(recipient: MessageRecipient, onUpdate: @escaping (MessageRecipient) -> Void, onDelete: @escaping () -> Void) {
        self.recipient = recipient
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedName = State(initialValue: recipient.name)
        self._editedPlatforms = State(initialValue: Set(recipient.platforms))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                VStack(spacing: 8) {
                    TextField("Nom", text: $editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text(recipient.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Plateformes")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(MessagePlatform.allCases) { platform in
                                PlatformToggleButton(
                                    platform: platform,
                                    isSelected: editedPlatforms.contains(platform)
                                ) {
                                    if editedPlatforms.contains(platform) {
                                        editedPlatforms.remove(platform)
                                    } else {
                                        editedPlatforms.insert(platform)
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Button("Annuler") {
                            cancelEdit()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Sauvegarder") {
                            saveEdit()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipient.name)
                            .font(.headline)
                        
                        Text(recipient.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            ForEach(recipient.platforms) { platform in
                                Image(systemName: platform.icon)
                                    .font(.caption2)
                                    .foregroundColor(Color(platform.color))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Modifier") {
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Supprimer") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func cancelEdit() {
        editedName = recipient.name
        editedPlatforms = Set(recipient.platforms)
        isEditing = false
    }
    
    private func saveEdit() {
        var updatedRecipient = recipient
        updatedRecipient.name = editedName
        updatedRecipient.platforms = Array(editedPlatforms)
        onUpdate(updatedRecipient)
        isEditing = false
    }
}

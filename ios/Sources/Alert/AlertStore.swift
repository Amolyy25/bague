import Foundation

struct AlertLog: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var timestamp: Date = Date()
}

struct PendingAlert: Codable {
    var body: String
    var timestamp: Date = Date()
}

final class AlertStore: ObservableObject {
    @Published private(set) var logs: [AlertLog] = []
    @Published private(set) var recipients: [String] = []
    @Published private(set) var pending: [PendingAlert] = []

    private let logsKey = "sr_logs"
    private let recipientsKey = "sr_recipients"
    private let pendingKey = "sr_pending"

    init() {
        load()
    }

    var hasPendingAlerts: Bool { !pending.isEmpty }

    func appendLog(title: String) {
        logs.insert(AlertLog(title: title), at: 0)
        persist()
    }

    func addRecipient(_ phone: String) {
        guard !recipients.contains(phone) else { return }
        recipients.append(phone)
        persist()
    }

    func removeRecipient(_ phone: String) {
        recipients.removeAll { $0 == phone }
        persist()
    }

    func appendPendingAlert(body: String) {
        pending.append(PendingAlert(body: body))
        persist()
    }

    func popNextPendingAlert() -> PendingAlert? {
        guard !pending.isEmpty else { return nil }
        let first = pending.removeFirst()
        persist()
        return first
    }

    private func persist() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(logs) { UserDefaults.standard.set(d, forKey: logsKey) }
        if let d = try? enc.encode(recipients) { UserDefaults.standard.set(d, forKey: recipientsKey) }
        if let d = try? enc.encode(pending) { UserDefaults.standard.set(d, forKey: pendingKey) }
    }

    private func load() {
        let dec = JSONDecoder()
        if let d = UserDefaults.standard.data(forKey: logsKey), let v = try? dec.decode([AlertLog].self, from: d) { logs = v }
        if let d = UserDefaults.standard.data(forKey: recipientsKey), let v = try? dec.decode([String].self, from: d) { recipients = v }
        if let d = UserDefaults.standard.data(forKey: pendingKey), let v = try? dec.decode([PendingAlert].self, from: d) { pending = v }
    }
}



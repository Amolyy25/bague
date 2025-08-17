import Foundation
import UserNotifications
import AVFoundation

final class AlertHandler: ObservableObject {
    static let alertNotificationName = Notification.Name("SafetyRingAlert")
    let alertPublisher = NotificationCenter.default.publisher(for: alertNotificationName)

    private let synthesizer = AVSpeechSynthesizer()

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func triggerLocalAlert() {
        // Local notification
        let content = UNMutableNotificationContent()
        content.title = "ALERTE SafetyRing"
        content.body = "Alerte reçue. Préparation du SMS."
        content.sound = .defaultCritical
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        // Haptic via speech cue (ensures some feedback even if haptics restricted)
        let utterance = AVSpeechUtterance(string: "Alerte reçue")
        synthesizer.speak(utterance)
    }
}



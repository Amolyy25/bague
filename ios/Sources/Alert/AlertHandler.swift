import Foundation
import UserNotifications
import AVFoundation
import UIKit

final class AlertHandler: ObservableObject {
    static let alertNotificationName = Notification.Name("SafetyRingAlert")
    let alertPublisher = NotificationCenter.default.publisher(for: alertNotificationName)

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func triggerLocalAlert() {
        // Local notification with custom sound
        let content = UNMutableNotificationContent()
        content.title = "🚨 ALERTE SafetyRing"
        content.body = "Alerte déclenchée ! Préparation du SMS d'urgence."
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Speech synthesis for accessibility
        let utterance = AVSpeechUtterance(string: "Alerte déclenchée")
        utterance.rate = 0.5
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    func playAlertSound(_ soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005) // System alert sound
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing alert sound: \(error)")
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    func stopAlertSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}



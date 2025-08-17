import SwiftUI

@main
struct SafetyRingApp: App {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var reachability = ReachabilityMonitor()
    @StateObject private var alertStore = AlertStore()
    @StateObject private var alertHandler = AlertHandler()
    @StateObject private var alertSettings = AlertSettingsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
                .environmentObject(locationManager)
                .environmentObject(reachability)
                .environmentObject(alertStore)
                .environmentObject(alertHandler)
                .environmentObject(alertSettings)
                .onAppear {
                    alertHandler.requestNotificationPermission()
                    bleManager.start()
                }
        }
    }
}


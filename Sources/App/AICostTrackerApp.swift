import SwiftUI

@main
struct AICostTrackerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView()
                .environmentObject(appState)
        } label: {
            MenuBarLabelView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Window("AI Cost Tracker Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .onDisappear {
                    // Revert to accessory so the app stays as menu-bar-only
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

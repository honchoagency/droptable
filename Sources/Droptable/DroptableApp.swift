import SwiftUI
import DroptableKit

@main
struct DroptableApp: App {
    @State private var settingsStore = SettingsStore()
    @State private var updateState = UpdateState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settingsStore)
                .environment(updateState)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(settingsStore)
                .environment(updateState)
        }
    }
}

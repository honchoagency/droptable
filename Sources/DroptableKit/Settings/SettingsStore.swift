import Foundation
import Observation

@MainActor
@Observable
public final class SettingsStore {
    private static let defaultsKey = "com.honcho.Droptable.settings"

    public var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
        }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

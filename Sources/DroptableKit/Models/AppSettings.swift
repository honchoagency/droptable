import Foundation

public enum DeletionMode: String, Codable, Sendable {
    case permanent
    case trash
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var extensionPatterns: [String]
    public var ignorePatterns: [String]
    public var deletionMode: DeletionMode
    public var ageFilterDays: Int
    public var onlyShowOlderThanThreshold: Bool
    public var scanRoots: [String]
    public var checkForUpdates: Bool

    public init(
        extensionPatterns: [String] = [".sql", ".sql.zip"],
        ignorePatterns: [String] = ["/vendor/", "~/Library", "~/Applications"],
        deletionMode: DeletionMode = .permanent,
        ageFilterDays: Int = 30,
        onlyShowOlderThanThreshold: Bool = false,
        scanRoots: [String] = ["~"],
        checkForUpdates: Bool = true
    ) {
        self.extensionPatterns = extensionPatterns
        self.ignorePatterns = ignorePatterns
        self.deletionMode = deletionMode
        self.ageFilterDays = ageFilterDays
        self.onlyShowOlderThanThreshold = onlyShowOlderThanThreshold
        self.scanRoots = scanRoots
        self.checkForUpdates = checkForUpdates
    }

    public static let `default` = AppSettings()

    // Custom decoding so a settings blob persisted before a field existed
    // (e.g. before `checkForUpdates` was added) falls back to its default
    // instead of failing to decode and silently resetting every setting.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        extensionPatterns = try c.decodeIfPresent([String].self, forKey: .extensionPatterns) ?? defaults.extensionPatterns
        ignorePatterns = try c.decodeIfPresent([String].self, forKey: .ignorePatterns) ?? defaults.ignorePatterns
        deletionMode = try c.decodeIfPresent(DeletionMode.self, forKey: .deletionMode) ?? defaults.deletionMode
        ageFilterDays = try c.decodeIfPresent(Int.self, forKey: .ageFilterDays) ?? defaults.ageFilterDays
        onlyShowOlderThanThreshold = try c.decodeIfPresent(Bool.self, forKey: .onlyShowOlderThanThreshold) ?? defaults.onlyShowOlderThanThreshold
        scanRoots = try c.decodeIfPresent([String].self, forKey: .scanRoots) ?? defaults.scanRoots
        checkForUpdates = try c.decodeIfPresent(Bool.self, forKey: .checkForUpdates) ?? defaults.checkForUpdates
    }
}

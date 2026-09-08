import Foundation
import Observation

@MainActor
@Observable
public final class ScanViewModel {
    public private(set) var records: [DatabaseFileRecord] = []
    public private(set) var isScanning = false
    public private(set) var warnings: [String] = []

    public var sortOrder: [KeyPathComparator<DatabaseFileRecord>] = [
        KeyPathComparator(\.filename)
    ]
    public var onlyShowOlderThanThreshold: Bool = false
    public var ageFilterDays: Int = 30

    private var streamTask: Task<Void, Never>?
    private let engine = ScanEngine()

    public init() {}

    public var displayedRecords: [DatabaseFileRecord] {
        var result = records
        if onlyShowOlderThanThreshold {
            let cutoff = Date().addingTimeInterval(-Double(ageFilterDays) * 86400)
            result = result.filter { record in
                guard let creationDate = record.creationDate else { return true }
                return creationDate <= cutoff
            }
        }
        result.sort(using: sortOrder)
        return result
    }

    public func startScan(settings: AppSettings) {
        guard !isScanning else { return }

        records = []
        warnings = []
        onlyShowOlderThanThreshold = settings.onlyShowOlderThanThreshold
        ageFilterDays = settings.ageFilterDays
        isScanning = true

        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = Self.resolveRoot(settings.scanRoots.first ?? "~", home: home)
        let extensions = settings.extensionPatterns
        let ignorePatterns = settings.ignorePatterns

        streamTask = Task { [engine] in
            for await event in engine.startScan(root: root, extensions: extensions, ignorePatterns: ignorePatterns) {
                if Task.isCancelled { break }
                switch event {
                case .found(let record):
                    records.append(record)
                case .warning(let path, let message):
                    warnings.append("\(path): \(message)")
                case .progress, .finished:
                    break
                }
            }
            isScanning = false
        }
    }

    public func stopScan() {
        engine.cancel()
        streamTask?.cancel()
        isScanning = false
    }

    public func removeRecords(withIDs ids: Set<DatabaseFileRecord.ID>) {
        records.removeAll { ids.contains($0.id) }
    }

    private static func resolveRoot(_ pattern: String, home: URL) -> URL {
        if pattern == "~" { return home }
        if pattern.hasPrefix("~/") { return home.appendingPathComponent(String(pattern.dropFirst(2))) }
        return URL(fileURLWithPath: pattern)
    }
}

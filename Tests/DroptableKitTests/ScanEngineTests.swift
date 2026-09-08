import Foundation
import Testing
@testable import DroptableKit

@Suite struct ScanEngineTests {
    @Test func findsMatchingFilesAndSkipsIgnoredDirectories() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let keepDir = root.appendingPathComponent("project")
        let vendorDir = root.appendingPathComponent("project/vendor")
        try fileManager.createDirectory(at: vendorDir, withIntermediateDirectories: true)

        try "dump".write(to: keepDir.appendingPathComponent("keep.sql"), atomically: true, encoding: .utf8)
        try "dump".write(to: keepDir.appendingPathComponent("keep.sql.zip"), atomically: true, encoding: .utf8)
        try "ignored".write(to: vendorDir.appendingPathComponent("ignored.sql"), atomically: true, encoding: .utf8)
        try "notes".write(to: keepDir.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)

        let engine = ScanEngine()
        var foundFilenames: [String] = []

        for await event in engine.startScan(
            root: root,
            extensions: [".sql", ".sql.zip"],
            ignorePatterns: ["/vendor/"]
        ) {
            if case .found(let record) = event {
                foundFilenames.append(record.filename)
            }
        }

        #expect(Set(foundFilenames) == Set(["keep.sql", "keep.sql.zip"]))
    }

    @Test func cancellationStopsEarly() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        for i in 0..<50 {
            try "dump".write(to: root.appendingPathComponent("file\(i).sql"), atomically: true, encoding: .utf8)
        }

        let engine = ScanEngine()
        let stream = engine.startScan(root: root, extensions: [".sql"], ignorePatterns: [])
        engine.cancel()

        var receivedFinished = false
        for await event in stream {
            if case .finished = event { receivedFinished = true }
        }
        #expect(receivedFinished)
    }
}

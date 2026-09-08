import Foundation

public enum ScanEvent: Sendable {
    case found(DatabaseFileRecord)
    case warning(path: String, message: String)
    case progress(scannedCount: Int)
    case finished
}

/// Walks a directory tree looking for files matching `extensions`, pruning
/// directories that match `ignorePatterns` before descending into them.
///
/// Not an actor: the only mutable state is the currently-running `Task`
/// handle, and the enumerator walk itself is inherently sequential.
public final class ScanEngine: @unchecked Sendable {
    private var currentTask: Task<Void, Never>?

    public init() {}

    public func startScan(root: URL, extensions: [String], ignorePatterns: [String]) -> AsyncStream<ScanEvent> {
        let home = FileManager.default.homeDirectoryForCurrentUser

        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                let resourceKeys: [URLResourceKey] = [
                    .isDirectoryKey, .creationDateKey, .fileSizeKey, .isSymbolicLinkKey,
                ]

                guard let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: resourceKeys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: { url, error in
                        continuation.yield(.warning(path: url.path, message: error.localizedDescription))
                        return true
                    }
                ) else {
                    continuation.yield(.finished)
                    continuation.finish()
                    return
                }

                var scannedCount = 0

                while let url = enumerator.nextObject() as? URL {
                    if Task.isCancelled { break }

                    let resourceValues: URLResourceValues
                    do {
                        resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
                    } catch {
                        continuation.yield(.warning(path: url.path, message: error.localizedDescription))
                        continue
                    }

                    if resourceValues.isDirectory == true {
                        if IgnoreMatcher.shouldIgnore(directory: url, patterns: ignorePatterns, home: home) {
                            enumerator.skipDescendants()
                        }
                        continue
                    }

                    if resourceValues.isSymbolicLink == true {
                        continue
                    }

                    scannedCount += 1
                    if scannedCount % 200 == 0 {
                        continuation.yield(.progress(scannedCount: scannedCount))
                    }

                    let filename = url.lastPathComponent
                    guard let matched = ExtensionMatcher.matchedExtension(for: filename, patterns: extensions) else {
                        continue
                    }

                    let record = DatabaseFileRecord(
                        url: url,
                        filename: filename,
                        matchedExtension: matched,
                        fileSizeBytes: Int64(resourceValues.fileSize ?? 0),
                        creationDate: resourceValues.creationDate
                    )
                    continuation.yield(.found(record))
                }

                continuation.yield(.finished)
                continuation.finish()
            }

            self.currentTask = task
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func cancel() {
        currentTask?.cancel()
    }
}

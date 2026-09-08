import Foundation

public struct DeletionResult: Sendable {
    public let record: DatabaseFileRecord
    public let outcome: Result<Void, DeletionError>
}

public struct DeletionError: Error, Sendable {
    public let localizedDescription: String
    public init(_ underlying: Error) {
        self.localizedDescription = underlying.localizedDescription
    }
}

public final class FileDeletionService: Sendable {
    public init() {}

    public func delete(_ records: [DatabaseFileRecord], mode: DeletionMode) async -> [DeletionResult] {
        await withTaskGroup(of: DeletionResult.self) { group in
            for record in records {
                group.addTask {
                    do {
                        switch mode {
                        case .permanent:
                            try FileManager.default.removeItem(at: record.url)
                        case .trash:
                            try FileManager.default.trashItem(at: record.url, resultingItemURL: nil)
                        }
                        return DeletionResult(record: record, outcome: .success(()))
                    } catch {
                        return DeletionResult(record: record, outcome: .failure(DeletionError(error)))
                    }
                }
            }

            var results: [DeletionResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}

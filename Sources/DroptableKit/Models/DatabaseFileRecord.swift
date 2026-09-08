import Foundation

public struct DatabaseFileRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL
    public let filename: String
    public let matchedExtension: String
    public let fileSizeBytes: Int64
    public let creationDate: Date?

    public var path: String { url.path }

    /// Non-optional stand-in for sorting purposes; unknown creation dates
    /// sort as though infinitely old rather than crashing/being excluded.
    public var creationDateSortValue: Date { creationDate ?? .distantPast }

    public init(
        url: URL,
        filename: String,
        matchedExtension: String,
        fileSizeBytes: Int64,
        creationDate: Date?
    ) {
        self.id = url.path
        self.url = url
        self.filename = filename
        self.matchedExtension = matchedExtension
        self.fileSizeBytes = fileSizeBytes
        self.creationDate = creationDate
    }
}

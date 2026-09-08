import Foundation

public enum ExtensionMatcher {
    /// Returns the pattern that matched `filename`, or nil if none did.
    ///
    /// Uses a filename suffix match rather than `URL.pathExtension`, because
    /// `pathExtension` only sees the last dot-component (`"zip"` for
    /// `dump.sql.zip`), which would miss the compound extensions this app
    /// cares about most (`.sql.zip`, `.sql.gz`, ...).
    public static func matchedExtension(for filename: String, patterns: [String]) -> String? {
        let lower = filename.lowercased()
        return patterns.first { pattern in
            let normalized = normalize(pattern)
            guard !normalized.isEmpty else { return false }
            return lower.hasSuffix(normalized.lowercased())
        }
    }

    /// Ensures a pattern starts with "." so user-entered patterns like "sql"
    /// or ".sql" both work.
    public static func normalize(_ pattern: String) -> String {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        return trimmed.hasPrefix(".") ? trimmed : ".\(trimmed)"
    }
}

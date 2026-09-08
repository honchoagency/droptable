import Testing
@testable import DroptableKit

@Suite struct ExtensionMatcherTests {
    @Test func matchesSimpleExtension() {
        #expect(ExtensionMatcher.matchedExtension(for: "dump.sql", patterns: [".sql", ".sql.zip"]) == ".sql")
    }

    @Test func matchesCompoundExtension() {
        #expect(ExtensionMatcher.matchedExtension(for: "dump.sql.zip", patterns: [".sql", ".sql.zip"]) == ".sql.zip")
    }

    @Test func doesNotFalsePositiveOnSimilarSuffix() {
        #expect(ExtensionMatcher.matchedExtension(for: "backup.sqlite", patterns: [".sql"]) == nil)
    }

    @Test func isCaseInsensitive() {
        #expect(ExtensionMatcher.matchedExtension(for: "DUMP.SQL.ZIP", patterns: [".sql.zip"]) == ".sql.zip")
    }

    @Test func normalizeAddsLeadingDot() {
        #expect(ExtensionMatcher.normalize("sql") == ".sql")
        #expect(ExtensionMatcher.normalize(".sql") == ".sql")
    }

    @Test func noMatchReturnsNil() {
        #expect(ExtensionMatcher.matchedExtension(for: "notes.txt", patterns: [".sql", ".sql.zip"]) == nil)
    }
}

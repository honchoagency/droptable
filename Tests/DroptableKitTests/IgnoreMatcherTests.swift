import Foundation
import Testing
@testable import DroptableKit

@Suite struct IgnoreMatcherTests {
    let home = URL(fileURLWithPath: "/Users/testuser")

    @Test func ignoresExactHomeRelativePath() {
        let dir = URL(fileURLWithPath: "/Users/testuser/Library")
        #expect(IgnoreMatcher.shouldIgnore(directory: dir, patterns: ["~/Library"], home: home))
    }

    @Test func ignoresDescendantOfHomeRelativePath() {
        let dir = URL(fileURLWithPath: "/Users/testuser/Library/Caches")
        #expect(IgnoreMatcher.shouldIgnore(directory: dir, patterns: ["~/Library"], home: home))
    }

    @Test func doesNotIgnoreUnrelatedSiblingOfHomeRelativePattern() {
        let dir = URL(fileURLWithPath: "/Users/testuser/LibraryStuff")
        #expect(!IgnoreMatcher.shouldIgnore(directory: dir, patterns: ["~/Library"], home: home))
    }

    @Test func ignoresPathComponentAnywhereInTree() {
        let dir = URL(fileURLWithPath: "/Users/testuser/Projects/app/vendor")
        #expect(IgnoreMatcher.shouldIgnore(directory: dir, patterns: ["/vendor/"], home: home))
    }

    @Test func doesNotFalsePositiveOnSimilarComponentName() {
        let dir = URL(fileURLWithPath: "/Users/testuser/Projects/myvendor")
        #expect(!IgnoreMatcher.shouldIgnore(directory: dir, patterns: ["/vendor/"], home: home))

        let dir2 = URL(fileURLWithPath: "/Users/testuser/Projects/vendor-scripts")
        #expect(!IgnoreMatcher.shouldIgnore(directory: dir2, patterns: ["/vendor/"], home: home))
    }

    @Test func noPatternsMatchesNothing() {
        let dir = URL(fileURLWithPath: "/Users/testuser/Projects/vendor")
        #expect(!IgnoreMatcher.shouldIgnore(directory: dir, patterns: [], home: home))
    }
}

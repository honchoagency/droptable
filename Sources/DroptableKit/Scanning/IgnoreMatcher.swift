import Foundation

public enum IgnoreMatcher {
    /// Two kinds of ignore pattern are supported, matching the defaults
    /// ("/vendor/", "~/Library", "~/Applications"):
    ///
    /// - A pattern starting with "~/" (or exactly "~") is an anchored
    ///   home-relative path: a directory is ignored if it equals, or is a
    ///   descendant of, `home` + the rest of the pattern.
    /// - Any other pattern is a path-component match: after trimming
    ///   leading/trailing slashes, a directory is ignored if any of its path
    ///   components exactly equals the pattern (so "/vendor/" matches a
    ///   `vendor` folder anywhere in the tree, but not `myvendor` or
    ///   `vendor-scripts`).
    public static func shouldIgnore(directory: URL, patterns: [String], home: URL) -> Bool {
        let standardizedDirectory = directory.standardizedFileURL
        let path = standardizedDirectory.path

        for rawPattern in patterns {
            let trimmed = rawPattern.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if trimmed == "~" || trimmed.hasPrefix("~/") {
                let rest = trimmed == "~" ? "" : String(trimmed.dropFirst(2))
                let anchor = rest.isEmpty
                    ? home.standardizedFileURL
                    : home.appendingPathComponent(rest).standardizedFileURL
                let anchorPath = anchor.path
                if path == anchorPath || path.hasPrefix(anchorPath + "/") {
                    return true
                }
            } else {
                let component = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                guard !component.isEmpty else { continue }
                if standardizedDirectory.pathComponents.contains(component) {
                    return true
                }
            }
        }
        return false
    }
}

import Foundation

/// Checks the public GitHub Releases API for a newer version — the release's
/// tag is the git tag (e.g. "v1.2.0"), which is where `build.sh` derives the
/// app's own `CFBundleShortVersionString` from in the first place.
public enum UpdateChecker {
    /// The latest release's version (tag with any leading "v" stripped), or nil.
    public static func latestVersion(repo: String) async -> String? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Droptable", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else { return nil }
        return tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    /// Dotted-number comparison: is `candidate` a newer version than `current`?
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        func parts(_ v: String) -> [Int] { v.split(separator: ".").compactMap { Int($0) } }
        let a = parts(candidate), b = parts(current)
        for i in 0 ..< max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

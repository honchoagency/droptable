import Foundation
import Observation

@MainActor
@Observable
public final class UpdateState {
    public private(set) var availableUpdate: String?
    public private(set) var isChecking = false

    public init() {}

    /// "owner/repo" baked into Info.plist by build.sh from the git remote.
    /// Blank/missing when there's no GitHub remote yet, which silently
    /// disables the check rather than erroring.
    public var githubRepo: String? {
        (Bundle.main.object(forInfoDictionaryKey: "GHRepo") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    public var releasesURL: URL? {
        githubRepo.flatMap { URL(string: "https://github.com/\($0)/releases/latest") }
    }

    public var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    public func checkForUpdate(enabled: Bool) async {
        guard enabled, let repo = githubRepo else { availableUpdate = nil; return }
        isChecking = true
        defer { isChecking = false }
        guard let latest = await UpdateChecker.latestVersion(repo: repo) else { return }
        availableUpdate = UpdateChecker.isNewer(latest, than: currentVersion) ? latest : nil
    }
}

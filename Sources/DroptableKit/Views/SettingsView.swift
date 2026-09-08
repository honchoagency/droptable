import SwiftUI

public struct SettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(UpdateState.self) private var updateState
    @State private var newExtensionPattern = ""
    @State private var newIgnorePattern = ""

    public init() {}

    public var body: some View {
        @Bindable var settingsStore = settingsStore

        Form {
            Section("File Extensions to Find") {
                ForEach(settingsStore.settings.extensionPatterns, id: \.self) { pattern in
                    HStack {
                        Text(pattern)
                        Spacer()
                        Button {
                            settingsStore.settings.extensionPatterns.removeAll { $0 == pattern }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("e.g. .sql.gz", text: $newExtensionPattern)
                    Button("Add") {
                        let normalized = ExtensionMatcher.normalize(newExtensionPattern)
                        guard !normalized.isEmpty, normalized != ".",
                              !settingsStore.settings.extensionPatterns.contains(normalized) else { return }
                        settingsStore.settings.extensionPatterns.append(normalized)
                        newExtensionPattern = ""
                    }
                    .disabled(newExtensionPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Folders to Ignore") {
                ForEach(settingsStore.settings.ignorePatterns, id: \.self) { pattern in
                    HStack {
                        Text(pattern)
                        Spacer()
                        Button {
                            settingsStore.settings.ignorePatterns.removeAll { $0 == pattern }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("e.g. /vendor/ or ~/Library", text: $newIgnorePattern)
                    Button("Add") {
                        let trimmed = newIgnorePattern.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty, !settingsStore.settings.ignorePatterns.contains(trimmed) else { return }
                        settingsStore.settings.ignorePatterns.append(trimmed)
                        newIgnorePattern = ""
                    }
                    .disabled(newIgnorePattern.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Deletion") {
                Picker("When deleting files", selection: $settingsStore.settings.deletionMode) {
                    Text("Permanently delete").tag(DeletionMode.permanent)
                    Text("Move to Trash").tag(DeletionMode.trash)
                }
                .pickerStyle(.radioGroup)

                Text(settingsStore.settings.deletionMode == .permanent
                     ? "Files are removed immediately and cannot be recovered. This is required for genuine GDPR compliance — items in the Trash still exist on disk."
                     : "Files are moved to the Trash and can be recovered until it is emptied.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Age Filter") {
                Stepper("Only show files older than \(settingsStore.settings.ageFilterDays) days",
                        value: $settingsStore.settings.ageFilterDays, in: 1...365)
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $settingsStore.settings.checkForUpdates)

                HStack {
                    Text("Droptable v\(updateState.currentVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let version = updateState.availableUpdate, let url = updateState.releasesURL {
                        Link("Update available (v\(version))", destination: url)
                    } else {
                        Button(updateState.isChecking ? "Checking…" : "Check Now") {
                            Task { await updateState.checkForUpdate(enabled: true) }
                        }
                        .disabled(updateState.isChecking || updateState.githubRepo == nil)
                    }
                }

                if updateState.githubRepo == nil {
                    Text("No GitHub remote is baked into this build, so update checks are disabled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 480, height: 560)
    }
}

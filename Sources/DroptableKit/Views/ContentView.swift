import SwiftUI

public struct ContentView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(UpdateState.self) private var updateState
    @State private var viewModel = ScanViewModel()
    @State private var selection = Set<DatabaseFileRecord.ID>()
    @State private var showDeleteConfirmation = false
    @State private var deletionErrors: [DeletionResult] = []
    @State private var showDeletionErrors = false

    private let deletionService = FileDeletionService()

    public init() {}

    public var body: some View {
        ResultsTableView(viewModel: viewModel, selection: $selection)
            .navigationTitle("Droptable")
            .toolbar {
                ToolbarItemGroup {
                    if viewModel.isScanning {
                        ProgressView()
                            .controlSize(.small)
                        Button("Stop") { viewModel.stopScan() }
                    } else {
                        Button("Scan") { viewModel.startScan(settings: settingsStore.settings) }
                    }

                    Toggle("Only >\(settingsStore.settings.ageFilterDays)d old", isOn: Binding(
                        get: { viewModel.onlyShowOlderThanThreshold },
                        set: { newValue in
                            viewModel.onlyShowOlderThanThreshold = newValue
                            settingsStore.settings.onlyShowOlderThanThreshold = newValue
                        }
                    ))

                    Button(selection.isEmpty ? "Delete Selected" : "Delete Selected (\(selection.count))") {
                        showDeleteConfirmation = true
                    }
                    .disabled(selection.isEmpty)

                    if let version = updateState.availableUpdate, let url = updateState.releasesURL {
                        Link("Update available (v\(version))", destination: url)
                    }
                }
            }
            .frame(minWidth: 720, minHeight: 420)
            .onAppear {
                viewModel.onlyShowOlderThanThreshold = settingsStore.settings.onlyShowOlderThanThreshold
                viewModel.ageFilterDays = settingsStore.settings.ageFilterDays
            }
            .task {
                await updateState.checkForUpdate(enabled: settingsStore.settings.checkForUpdates)
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeleteConfirmationView(
                    records: viewModel.records.filter { selection.contains($0.id) },
                    mode: settingsStore.settings.deletionMode,
                    onCancel: { showDeleteConfirmation = false },
                    onConfirm: { records in
                        showDeleteConfirmation = false
                        performDeletion(records)
                    }
                )
            }
            .sheet(isPresented: $showDeletionErrors) {
                DeletionErrorsView(results: deletionErrors, onDismiss: { showDeletionErrors = false })
            }
    }

    private func performDeletion(_ records: [DatabaseFileRecord]) {
        let mode = settingsStore.settings.deletionMode
        Task {
            let results = await deletionService.delete(records, mode: mode)

            let succeededIDs = Set(results.compactMap { result -> DatabaseFileRecord.ID? in
                if case .success = result.outcome { return result.record.id }
                return nil
            })
            viewModel.removeRecords(withIDs: succeededIDs)
            selection.subtract(succeededIDs)

            let failures = results.filter {
                if case .failure = $0.outcome { return true }
                return false
            }
            if !failures.isEmpty {
                deletionErrors = failures
                showDeletionErrors = true
            }
        }
    }
}

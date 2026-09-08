import SwiftUI

struct ResultsTableView: View {
    @Bindable var viewModel: ScanViewModel
    @Binding var selection: Set<DatabaseFileRecord.ID>

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            Table(viewModel.displayedRecords, selection: $selection, sortOrder: $viewModel.sortOrder) {
                TableColumn("Name", value: \.filename)
                TableColumn("Path", value: \.path)
                TableColumn("Created", value: \.creationDateSortValue) { record in
                    Text(record.creationDate.map { Self.dateFormatter.string(from: $0) } ?? "Unknown")
                }
                TableColumn("Size", value: \.fileSizeBytes) { record in
                    Text(ByteCountFormatter.string(fromByteCount: record.fileSizeBytes, countStyle: .file))
                }
            }

            if !viewModel.warnings.isEmpty {
                Divider()
                Text("\(viewModel.warnings.count) folder(s) could not be scanned (permission denied).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

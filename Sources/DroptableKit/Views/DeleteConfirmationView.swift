import SwiftUI

struct DeleteConfirmationView: View {
    let records: [DatabaseFileRecord]
    let mode: DeletionMode
    let onCancel: () -> Void
    let onConfirm: ([DatabaseFileRecord]) -> Void

    @State private var acknowledgedPermanent = false

    private var totalBytes: Int64 {
        records.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode == .permanent
                 ? "Permanently delete \(records.count) file(s)?"
                 : "Move \(records.count) file(s) to Trash?")
                .font(.title2.bold())

            Text(mode == .permanent
                 ? "This cannot be undone."
                 : "You can recover these later from the Trash.")
                .foregroundStyle(.secondary)

            Text("Total size: \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            List(records) { record in
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.filename)
                    Text(record.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 200)

            if mode == .permanent {
                Toggle("I understand this is permanent and cannot be undone.", isOn: $acknowledgedPermanent)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                Button(mode == .permanent ? "Delete Permanently" : "Move to Trash", role: .destructive) {
                    onConfirm(records)
                }
                .disabled(mode == .permanent && !acknowledgedPermanent)
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 420)
    }
}

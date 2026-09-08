import SwiftUI

struct DeletionErrorsView: View {
    let results: [DeletionResult]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Some files could not be deleted")
                .font(.title2.bold())

            List(results, id: \.record.id) { result in
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.record.filename)
                    if case .failure(let error) = result.outcome {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 200)

            HStack {
                Spacer()
                Button("OK") { onDismiss() }
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 360)
    }
}

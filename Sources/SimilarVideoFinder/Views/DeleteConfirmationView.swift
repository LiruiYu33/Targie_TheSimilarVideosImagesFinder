import SwiftUI

struct DeleteConfirmationView: View {
    @ObservedObject var model: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let prompt = model.deletePrompt {
                Image(systemName: prompt.step == .choosingMethod ? "trash" : "exclamationmark.triangle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(prompt.step == .choosingMethod ? Color.secondary : Color.red)

                Text(prompt.step == .choosingMethod ? L10n.deleteHow(language) : L10n.permanentWarningTitle(language))
                    .font(.title2.bold())
                Text(prompt.video.filename).font(.headline)
                Text(prompt.video.url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if prompt.step == .choosingMethod {
                    Text(L10n.trashExplanation(language))
                        .foregroundStyle(.secondary)
                    HStack {
                        Button(L10n.cancel(language)) { cancel() }
                            .keyboardShortcut(.cancelAction)
                        Spacer()
                        Button(L10n.permanentDelete(language)) { model.askForPermanentConfirmation() }
                        Button(L10n.moveToTrash(language)) {
                            Task {
                                await model.confirmDeletion(of: prompt.video, mode: .trash)
                                if model.deletePrompt == nil { dismiss() }
                            }
                        }
                    }
                } else {
                    Text(L10n.irreversible(language))
                        .foregroundStyle(.red)
                    HStack {
                        Button(L10n.cancel(language)) { cancel() }
                            .keyboardShortcut(.cancelAction)
                        Spacer()
                        Button(L10n.back(language)) {
                            model.deletePrompt = DeletePrompt(video: prompt.video, step: .choosingMethod)
                        }
                        Button(L10n.confirmPermanent(language), role: .destructive) {
                            Task {
                                await model.confirmDeletion(of: prompt.video, mode: .permanent)
                                if model.deletePrompt == nil { dismiss() }
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private func cancel() {
        model.deletePrompt = nil
        dismiss()
    }
}

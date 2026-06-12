import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: ScanViewModel
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            groupList
        }
        .navigationTitle(L10n.similarVideos(language))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { model.chooseFolder(language: language) }) {
                Label(model.selectedFolder == nil ? L10n.chooseFolder(language) : L10n.changeFolder(language), systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            if let folder = model.selectedFolder {
                Text(folder.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .help(folder.path)
            }

            if model.isScanning {
                ProgressView(value: model.progress.fraction) {
                    Text(L10n.scanStage(model.progress.stage, language))
                } currentValueLabel: {
                    Text(model.progress.currentFile)
                        .lineLimit(1)
                }
                Button(L10n.cancelScan(language), role: .cancel, action: model.cancelScan)
            } else {
                Button(action: model.startScan) {
                    Label(L10n.startScan(language), systemImage: "sparkle.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.selectedFolder == nil)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(L10n.displayThreshold(language))
                    Spacer()
                    Text(DisplayFormatters.percent(model.threshold)).monospacedDigit()
                }
                .font(.caption)
                Slider(value: $model.threshold, in: 0.72...0.98, step: 0.01)
            }

            if !model.issues.isEmpty {
                Label(L10n.skippedFiles(model.issues.count, language), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help(model.issues.map { "\($0.url.lastPathComponent): \($0.message(language: language))" }.joined(separator: "\n"))
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var groupList: some View {
        if model.groups.isEmpty {
            ContentUnavailableView(
                model.progress.stage == .completed ? L10n.noSimilarVideos(language) : L10n.waitingToScan(language),
                systemImage: model.progress.stage == .completed ? "checkmark.circle" : "film.stack",
                description: Text(model.progress.stage == .completed ? L10n.lowerThresholdHint(language) : L10n.chooseAndScanHint(language))
            )
        } else {
            List(selection: Binding(
                get: { model.selectedGroupID },
                set: { model.selectGroup($0) }
            )) {
                ForEach(Array(model.groups.enumerated()), id: \.element.id) { index, group in
                    HStack(spacing: 10) {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.similarGroup(index + 1, language))
                            Text(L10n.videoCountAndScore(group.videos.count, DisplayFormatters.percent(group.maximumScore), language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(group.id)
                }
            }
            .listStyle(.sidebar)
        }
    }
}

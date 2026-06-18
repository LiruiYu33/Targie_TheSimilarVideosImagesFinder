// Targie — Find similar videos on macOS.
// Copyright (C) 2026 Lirui Yu
//
// This file is part of Targie.
//
// Targie is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Targie is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Targie.  If not, see <https://www.gnu.org/licenses/>.
//
// If you reuse this code (modified or not), you must keep this notice
// and credit the original author (Lirui Yu).

import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: ScanViewModel
    @Environment(\.appLanguage) private var language
    @State private var showSkippedFiles = false

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            groupList
        }
        .navigationTitle(L10n.similarMedia(language))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { model.chooseFolder(language: language) }) {
                Label(L10n.addFolders(language), systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(model.isScanning)

            if model.selectedFolders.isEmpty {
                Text(L10n.dragFoldersHint(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.foldersSelected(model.selectedFolders.count, language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(model.selectedFolders, id: \.self) { folder in
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(folder.path)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(folder.path)
                        Spacer(minLength: 0)
                        Button {
                            model.removeFolder(folder)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isScanning)
                        .foregroundStyle(.secondary)
                        .help(L10n.removeFolder(language))
                    }
                }
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
                .disabled(model.selectedFolders.isEmpty)
            }

            DisplayThresholdControl(threshold: $model.threshold, language: language)

            if !model.issues.isEmpty {
                Button { showSkippedFiles.toggle() } label: {
                    Label(L10n.skippedFiles(model.issues.count, language), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSkippedFiles) {
                    SkippedFilesList(issues: model.issues, language: language)
                }
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var groupList: some View {
        if model.groups.isEmpty {
            ContentUnavailableView(
                model.progress.stage == .completed ? L10n.noSimilarMedia(language) : L10n.waitingToScan(language),
                systemImage: model.progress.stage == .completed ? "checkmark.circle" : "photo.stack",
                description: Text(model.progress.stage == .completed ? L10n.lowerThresholdHint(language) : L10n.chooseAndScanHint(language))
            )
        } else {
            List(selection: Binding(
                get: { model.selectedGroupID },
                set: { model.selectGroup($0) }
            )) {
                if model.scanMode == .all {
                    Section(L10n.videos(language)) { groupRows(model.groups.filter { $0.items.first?.kind == .video }) }
                    Section(L10n.images(language)) { groupRows(model.groups.filter { $0.items.first?.kind == .image }) }
                } else {
                    groupRows(model.groups)
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func groupRows(_ groups: [SimilarityGroup]) -> some View {
        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
            HStack(spacing: 10) {
                Image(systemName: group.items.first?.kind == .image ? "photo.stack" : "film.stack")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.similarGroup(index + 1, language))
                    Text(L10n.mediaCountAndScore(group.items.count, DisplayFormatters.percent(group.maximumScore), language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tag(group.id)
        }
    }
}

// MARK: - Display Threshold

private struct DisplayThresholdControl: View {
    @Binding var threshold: Double
    let language: AppLanguage

    @State private var editState = DisplayThresholdTextEditState(threshold: DisplayThresholdEditing.recommendedThreshold)
    @FocusState private var isThresholdTextFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(L10n.displayThreshold(language))
                Spacer()
                HStack(spacing: 2) {
                    if editState.isEditing {
                        TextField(
                            L10n.displayThreshold(language),
                            text: Binding(
                                get: { editState.editText },
                                set: { editState.editText = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(width: 54)
                        .focused($isThresholdTextFocused)
                        .onSubmit(commitThresholdText)
                    } else {
                        Button {
                            beginThresholdTextEditing()
                        } label: {
                            Text(editState.displayText)
                                .monospacedDigit()
                                .frame(width: 42, alignment: .trailing)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.secondary.opacity(0.45), lineWidth: 1)
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Text("%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .background(
                    ClickOutsideMonitor(
                        isActive: editState.isEditing,
                        onClickOutside: commitThresholdText
                    )
                )
            }
            .font(.caption)

            Slider(
                value: Binding(
                    get: { threshold },
                    set: { threshold = DisplayThresholdEditing.sliderValue(for: $0) }
                ),
                in: ScanViewModel.displayThresholdRange,
                step: 0.01
            ) {
                EmptyView()
            } minimumValueLabel: {
                Text("60%").font(.system(size: 9)).foregroundStyle(.tertiary)
            } maximumValueLabel: {
                Text("100%").font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            .help(L10n.displayThresholdHelp(language))

            if threshold < DisplayThresholdEditing.recommendedThreshold {
                Text(L10n.displayThresholdHelp(language))
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .onAppear { editState.syncThreshold(threshold) }
        .onChange(of: threshold) { _, _ in
            editState.syncThreshold(threshold)
        }
        .onChange(of: isThresholdTextFocused) { _, isFocused in
            if !isFocused && editState.isEditing {
                commitThresholdText()
            }
        }
    }

    private func beginThresholdTextEditing() {
        editState.syncThreshold(threshold)
        editState.beginEditing()
        DispatchQueue.main.async {
            isThresholdTextFocused = true
        }
    }

    private func commitThresholdText() {
        editState.commitCurrentText()
        threshold = editState.threshold
        isThresholdTextFocused = false
    }
}

// MARK: - Skipped Files Popover

struct SkippedFilesList: View {
    let issues: [ScanIssue]
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.skippedFiles(issues.count, language))
                .font(.headline)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.url.lastPathComponent)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(issue.message(language: language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(issue.url.deletingLastPathComponent().path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .frame(width: 320, height: min(CGFloat(issues.count) * 60 + 60, 400))
    }
}

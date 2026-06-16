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

import AppKit
import SwiftUI

struct BrowseTableView: View {
    @ObservedObject var browseModel: BrowseViewModel
    @Environment(\.appLanguage) private var language

    var body: some View {
        if browseModel.scanModel.isScanning && browseModel.scanModel.items.isEmpty {
            VStack(spacing: 12) {
                ProgressView(value: browseModel.scanModel.progress.fraction) {
                    Text(L10n.scanStage(browseModel.scanModel.progress.stage, language))
                } currentValueLabel: {
                    Text(browseModel.scanModel.progress.currentFile)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .controlSize(.large)
                .frame(maxWidth: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if browseModel.displayedItems.isEmpty {
            ContentUnavailableView(
                L10n.noItemsToBrowse(language),
                systemImage: "doc.questionmark",
                description: Text(L10n.noItemsBrowseHint(language))
            )
        } else {
            VStack(spacing: 0) {
                // Sortable column header bar
                browseTableHeader
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.bar)

                Divider()

                // Native Table with resizable columns (no sortOrder —
                // sorting is handled manually so columns stay resizable).
                Table(browseModel.displayedItems, selection: Binding(
                    get: { browseModel.selectedMediaID },
                    set: { browseModel.selectMedia($0) }
                )) {
                    TableColumn(L10n.thumbnail(language)) { item in
                        BrowseThumbnailCell(item: item)
                    }
                    .width(min: 48, ideal: 60, max: 80)

                    TableColumn(L10n.name(language)) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.kind == .video ? "film" : "photo")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text(item.filename)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .width(min: 120, ideal: 250)

                    TableColumn(L10n.fileSize(language)) { item in
                        Text(DisplayFormatters.fileSize(item.fileSize))
                            .monospacedDigit()
                    }
                    .width(min: 60, ideal: 90, max: 120)

                    TableColumn(L10n.resolution(language)) { item in
                        Text(item.resolution(language: language))
                            .monospacedDigit()
                    }
                    .width(min: 80, ideal: 110, max: 150)

                    TableColumn(L10n.modifiedTime(language)) { item in
                        if let date = item.modifiedAt {
                            Text(date, style: .date)
                        } else {
                            Text("—").foregroundStyle(.tertiary)
                        }
                    }
                    .width(min: 80, ideal: 120, max: 160)
                }
                .alternatingRowBackgrounds(.enabled)
                .tableStyle(.inset(alternatesRowBackgrounds: true))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Table Header (sort controls)

    private var browseTableHeader: some View {
        HStack(spacing: 0) {
            headerLabel(L10n.thumbnail(language), width: 60)

            sortHeader(L10n.name(language), field: .name, fill: true)

            sortHeader(L10n.fileSize(language), field: .fileSize, fill: false, width: 90)

            resolutionSortHeader

            sortHeader(L10n.modifiedTime(language), field: .modifiedTime, fill: false, width: 120)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func headerLabel(_ text: String, width: CGFloat) -> some View {
        Text(text).frame(width: width, alignment: .leading)
    }

    private func sortHeader(_ text: String, field: BrowseViewModel.SortField, fill: Bool, width: CGFloat? = nil) -> some View {
        Button { browseModel.toggleSort(field: field) } label: {
            HStack(spacing: 4) {
                Text(text)
                if browseModel.sortField == field {
                    Image(systemName: browseModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
            .if(fill) { $0.frame(maxWidth: .infinity, alignment: .leading) }
            .if(!fill && width != nil) { $0.frame(width: width!, alignment: .leading) }
        }
        .buttonStyle(.plain)
    }

    private var resolutionSortHeader: some View {
        Button { browseModel.isResolutionSortPresented.toggle() } label: {
            HStack(spacing: 4) {
                Text(L10n.resolution(language))
                if browseModel.sortField.isResolution {
                    Image(systemName: browseModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
            .frame(width: 110, alignment: .leading)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $browseModel.isResolutionSortPresented) {
            BrowseResolutionSortPopover(browseModel: browseModel, language: language)
        }
    }
}

// MARK: - View Extension for conditional modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Table Row (kept for shared use)

struct BrowseThumbnailCell: View {
    let item: MediaItem

    var body: some View {
        Group {
            if let data = item.thumbnailData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: item.kind == .video ? "film" : "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Resolution Sort Popover

struct BrowseResolutionSortPopover: View {
    @ObservedObject var browseModel: BrowseViewModel
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.resolutionSort(language))
                    .font(.headline)
                Text(L10n.sortBy(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: Binding(
                    get: { browseModel.sortField.isResolution ? browseModel.sortField : .resolutionWidth },
                    set: { browseModel.sortField = $0; browseModel.sortAscending = true }
                )) {
                    Text(L10n.sortByWidth(language)).tag(BrowseViewModel.SortField.resolutionWidth)
                    Text(L10n.sortByHeight(language)).tag(BrowseViewModel.SortField.resolutionHeight)
                }
                .pickerStyle(.segmented)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.sortDirection(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $browseModel.sortAscending) {
                    Text(L10n.ascending(language)).tag(true)
                    Text(L10n.descending(language)).tag(false)
                }
                .pickerStyle(.segmented)
            }

            if browseModel.sortField.isResolution {
                Button(L10n.clearFilter(language), action: browseModel.clearResolutionSort)
                    .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

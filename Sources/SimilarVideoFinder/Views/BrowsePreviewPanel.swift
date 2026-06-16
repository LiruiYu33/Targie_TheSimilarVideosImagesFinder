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

struct BrowsePreviewPanel: View {
    @ObservedObject var browseModel: BrowseViewModel
    @Environment(\.appLanguage) private var language

    var body: some View {
        Group {
            if let media = browseModel.selectedMedia {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        MediaPreview(media: media)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(media.filename)
                                .font(.title3.bold())
                                .textSelection(.enabled)
                            metadata(L10n.fileSize(language), DisplayFormatters.fileSize(media.fileSize))
                            if let duration = media.duration {
                                metadata(L10n.duration(language), DisplayFormatters.duration(duration, language: language))
                            }
                            metadata(L10n.resolution(language), media.resolution(language: language))
                            metadata(L10n.path(language), media.url.path)
                        }

                        HStack {
                            if media.kind == .video {
                                Button(L10n.openDefaultPlayer(language)) { browseModel.scanModel.openMedia(media) }
                            }
                            Button(L10n.showInFinder(language)) { browseModel.scanModel.revealMedia(media) }
                        }
                        .controlSize(.small)

                        Divider()
                        Button(role: .destructive) {
                            browseModel.scanModel.requestDeletion(of: media)
                        } label: {
                            Label(L10n.deleteMedia(language), systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(18)
                }
            } else {
                ContentUnavailableView(
                    L10n.selectMedia(language),
                    systemImage: "rectangle.and.hand.point.up.left",
                    description: Text(L10n.selectMediaHint(language))
                )
            }
        }
        .navigationTitle("")
    }

    private func metadata(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}

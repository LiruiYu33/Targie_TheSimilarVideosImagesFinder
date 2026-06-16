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

struct BrowseView: View {
    @ObservedObject var browseModel: BrowseViewModel
    let onBack: () -> Void
    @Environment(\.appLanguage) private var language

    var body: some View {
        NavigationSplitView {
            BrowseTableView(browseModel: browseModel)
                .navigationSplitViewColumnWidth(min: 500, ideal: 800)
        } detail: {
            BrowsePreviewPanel(browseModel: browseModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 390)
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: onBack) {
                    Label(L10n.back(language), systemImage: "chevron.left")
                }

                Button {
                    browseModel.isFilterPresented.toggle()
                } label: {
                    if browseModel.hasActiveFilter {
                        Label(L10n.filter(language), systemImage: "line.3.horizontal.decrease.circle.fill")
                    } else {
                        Label(L10n.filter(language), systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                .popover(isPresented: $browseModel.isFilterPresented) {
                    BrowseFilterPopover(browseModel: browseModel)
                }

                Text(L10n.browseItemCount(browseModel.displayedItems.count, language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.browse(language))
    }
}

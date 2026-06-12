import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var model: ScanViewModel
    @Environment(\.appLanguage) private var language

    var body: some View {
        Group {
            if let group = model.selectedGroup {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.compareVideos(language))
                                    .font(.title2.bold())
                                Text(L10n.compareHint(language))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(L10n.highestSimilarity(DisplayFormatters.percent(group.maximumScore), language))
                                .font(.callout.weight(.medium))
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                            ForEach(group.videos) { video in
                                VideoCardView(
                                    video: video,
                                    score: group.score(for: video.id),
                                    evidence: group.evidence(for: video.id),
                                    language: language,
                                    isSelected: model.selectedVideoID == video.id
                                )
                                .onTapGesture { model.selectedVideoID = video.id }
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    L10n.selectGroup(language),
                    systemImage: "rectangle.3.group",
                    description: Text(L10n.resultsOnLeft(language))
                )
            }
        }
        .navigationTitle(model.selectedGroup == nil ? L10n.videoComparison(language) : L10n.similarVideoCount(model.selectedGroup!.videos.count, language))
    }
}

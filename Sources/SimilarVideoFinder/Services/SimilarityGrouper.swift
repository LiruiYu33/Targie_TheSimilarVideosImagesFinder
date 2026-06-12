import Foundation

enum SimilarityGrouper {
    static func groups(
        items: [VideoItem],
        relations: [SimilarityRelation],
        threshold: Double
    ) -> [SimilarityGroup] {
        let accepted = relations.filter { $0.score >= threshold }
        var adjacency: [UUID: Set<UUID>] = [:]
        for relation in accepted {
            adjacency[relation.firstID, default: []].insert(relation.secondID)
            adjacency[relation.secondID, default: []].insert(relation.firstID)
        }

        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var visited = Set<UUID>()
        var result: [SimilarityGroup] = []

        for item in items where !visited.contains(item.id) && adjacency[item.id] != nil {
            var stack = [item.id]
            var component = Set<UUID>()
            while let current = stack.popLast() {
                guard visited.insert(current).inserted else { continue }
                component.insert(current)
                stack.append(contentsOf: adjacency[current, default: []])
            }
            let videos = component.compactMap { byID[$0] }.sorted { $0.filename < $1.filename }
            guard videos.count >= 2 else { continue }
            let componentRelations = accepted.filter {
                component.contains($0.firstID) && component.contains($0.secondID)
            }
            result.append(SimilarityGroup(videos: videos, relations: componentRelations))
        }

        return result.sorted {
            if $0.maximumScore == $1.maximumScore { return $0.reclaimableBytes > $1.reclaimableBytes }
            return $0.maximumScore > $1.maximumScore
        }
    }
}

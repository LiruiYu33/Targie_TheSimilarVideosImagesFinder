import Foundation

struct PipelineResult: Sendable {
    let videos: [VideoItem]
    let relations: [SimilarityRelation]
    let groups: [SimilarityGroup]
}

protocol SimilarityProcessing: Sendable {
    func process(
        videos: [VideoItem],
        threshold: Double,
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async throws -> PipelineResult
}

struct SimilarityPipeline: SimilarityProcessing {
    private let extractor = FrameFeatureExtractor()

    func process(
        videos: [VideoItem],
        threshold: Double,
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async throws -> PipelineResult {
        let pairs = candidates(from: videos)
        var relations: [SimilarityRelation] = []
        var hashes: [UUID: String] = [:]

        for (index, pair) in pairs.enumerated() {
            try Task.checkCancellation()
            let sameSize = pair.0.fileSize > 0 && pair.0.fileSize == pair.1.fileSize
            var hashMatch = false
            if sameSize {
                let firstHash = try await hash(for: pair.0, cache: &hashes)
                let secondHash = try await hash(for: pair.1, cache: &hashes)
                hashMatch = firstHash == secondHash
            }
            let frameScore = hashMatch ? nil : try? await extractor.similarity(between: pair.0.url, and: pair.1.url)
            let score = SimilarityScorer.score(pair.0, pair.1, hashesMatch: hashMatch, frameSimilarity: frameScore)
            if score.score >= min(threshold, 0.72) {
                relations.append(SimilarityRelation(
                    firstID: pair.0.id,
                    secondID: pair.1.id,
                    score: score.score,
                    evidence: score.evidence
                ))
            }
            await progress(ScanProgress(
                stage: .comparing,
                fraction: pairs.isEmpty ? 1 : Double(index + 1) / Double(pairs.count),
                currentFile: pair.0.filename + " ↔ " + pair.1.filename,
                discoveredCount: videos.count
            ))
        }

        return PipelineResult(
            videos: videos,
            relations: relations,
            groups: SimilarityGrouper.groups(items: videos, relations: relations, threshold: threshold)
        )
    }

    private func hash(for video: VideoItem, cache: inout [UUID: String]) async throws -> String {
        if let cached = cache[video.id] { return cached }
        let value = try await FileHasher.sha256(of: video.url)
        cache[video.id] = value
        return value
    }

    private func candidates(from videos: [VideoItem]) -> [(VideoItem, VideoItem)] {
        guard videos.count > 1 else { return [] }
        var result: [(VideoItem, VideoItem)] = []
        for firstIndex in 0..<(videos.count - 1) {
            for secondIndex in (firstIndex + 1)..<videos.count {
                let first = videos[firstIndex]
                let second = videos[secondIndex]
                if isCandidate(first, second) { result.append((first, second)) }
            }
        }
        return result
    }

    private func isCandidate(_ first: VideoItem, _ second: VideoItem) -> Bool {
        let namesMatch = FilenameNormalizer.normalize(first.filename) == FilenameNormalizer.normalize(second.filename)
        let durationRatio = ratio(first.duration, second.duration)
        let sizeRatio = ratio(Double(first.fileSize), Double(second.fileSize))
        let firstAspect = first.height == 0 ? 0 : Double(first.width) / Double(first.height)
        let secondAspect = second.height == 0 ? 0 : Double(second.width) / Double(second.height)
        let aspectsMatch = firstAspect > 0 && secondAspect > 0 && abs(firstAspect - secondAspect) < 0.03
        return namesMatch || durationRatio >= 0.88 || sizeRatio >= 0.65 || aspectsMatch
    }

    private func ratio(_ lhs: Double, _ rhs: Double) -> Double {
        guard lhs > 0, rhs > 0 else { return 0 }
        return min(lhs, rhs) / max(lhs, rhs)
    }
}

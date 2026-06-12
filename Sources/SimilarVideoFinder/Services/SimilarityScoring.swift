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

import Foundation

enum FilenameNormalizer {
    static func normalize(_ filename: String) -> String {
        var value = (filename as NSString).deletingPathExtension.lowercased()
        let patterns = [
            #"(copy|副本|export|导出)[\s_\-]*\d*"#,
            #"[\s_\-]+\d+$"#,
            #"[\s_\-\(\)\[\]\.]+"#
        ]
        for pattern in patterns {
            value = value.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SimilarityScore: Equatable, Sendable {
    let score: Double
    let evidence: Set<SimilarityEvidence>
}

enum SimilarityScorer {
    static func score(
        _ first: VideoItem,
        _ second: VideoItem,
        hashesMatch: Bool,
        frameSimilarity: Double?
    ) -> SimilarityScore {
        if hashesMatch {
            return SimilarityScore(score: 1, evidence: [.identicalContentHash])
        }

        let duration = ratioScore(first.duration, second.duration)
        let size = ratioScore(Double(first.fileSize), Double(second.fileSize))
        let dimensions = dimensionScore(first, second)
        let name = nameScore(first.filename, second.filename)
        var evidence = Set<SimilarityEvidence>()
        if duration >= 0.9 { evidence.insert(.similarDuration) }
        if size >= 0.85 { evidence.insert(.similarSize) }
        if dimensions >= 0.95 { evidence.insert(.similarDimensions) }
        if name >= 0.85 { evidence.insert(.similarName) }

        let metadata = duration * 0.30 + dimensions * 0.20 + size * 0.20 + name * 0.30
        guard let frameSimilarity else {
            return SimilarityScore(score: min(metadata * 0.78, 0.78), evidence: evidence)
        }

        let frames = min(max(frameSimilarity, 0), 1)
        if frames >= 0.82 { evidence.insert(.similarFrames) }
        return SimilarityScore(score: min(frames * 0.70 + metadata * 0.30, 1), evidence: evidence)
    }

    private static func ratioScore(_ lhs: Double, _ rhs: Double) -> Double {
        guard lhs > 0, rhs > 0 else { return 0 }
        return min(lhs, rhs) / max(lhs, rhs)
    }

    private static func dimensionScore(_ first: VideoItem, _ second: VideoItem) -> Double {
        guard first.width > 0, first.height > 0, second.width > 0, second.height > 0 else { return 0 }
        let firstRatio = Double(first.width) / Double(first.height)
        let secondRatio = Double(second.width) / Double(second.height)
        let aspect = min(firstRatio, secondRatio) / max(firstRatio, secondRatio)
        let pixelsA = Double(first.width * first.height)
        let pixelsB = Double(second.width * second.height)
        return aspect * 0.7 + (min(pixelsA, pixelsB) / max(pixelsA, pixelsB)) * 0.3
    }

    private static func nameScore(_ lhs: String, _ rhs: String) -> Double {
        let a = FilenameNormalizer.normalize(lhs)
        let b = FilenameNormalizer.normalize(rhs)
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        if a == b { return 1 }
        if a.contains(b) || b.contains(a) { return 0.85 }
        return 0
    }
}

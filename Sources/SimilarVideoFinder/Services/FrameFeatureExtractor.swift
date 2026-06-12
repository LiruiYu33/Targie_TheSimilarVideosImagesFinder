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

import AVFoundation
import Foundation
@preconcurrency import Vision

enum FrameSimilarityAggregator {
    static func aggregate(_ values: [Double?]) -> Double? {
        let valid = values.compactMap { $0 }
        guard valid.count >= 2 else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }
}

struct FrameFeatureExtractor {
    static let samplePositions = [0.08, 0.28, 0.50, 0.72, 0.92]

    func similarity(between firstURL: URL, and secondURL: URL) async throws -> Double? {
        let first = try await observations(for: firstURL)
        let second = try await observations(for: secondURL)
        let count = min(first.count, second.count)
        var similarities: [Double?] = []
        for index in 0..<count {
            try Task.checkCancellation()
            guard let lhs = first[index], let rhs = second[index] else {
                similarities.append(nil)
                continue
            }
            var distance: Float = 0
            try lhs.computeDistance(&distance, to: rhs)
            similarities.append(max(0, min(1, 1 - Double(distance) / 40)))
        }
        return FrameSimilarityAggregator.aggregate(similarities)
    }

    private func observations(for url: URL) async throws -> [VNFeaturePrintObservation?] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else { return [] }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.35, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.35, preferredTimescale: 600)

        return try Self.samplePositions.map { position in
            try Task.checkCancellation()
            let time = CMTime(seconds: duration * position, preferredTimescale: 600)
            guard let image = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
            let request = VNGenerateImageFeaturePrintRequest()
            try VNImageRequestHandler(cgImage: image).perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        }
    }
}

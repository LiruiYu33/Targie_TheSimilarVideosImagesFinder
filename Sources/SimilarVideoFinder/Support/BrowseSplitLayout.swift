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

import CoreGraphics

enum BrowseSplitLayout {
    static let storageKey = "browseSplitLeftFraction"
    static let defaultLeftFraction = 0.65
    static let minTableWidth: CGFloat = 80
    static let minPreviewWidth: CGFloat = 80

    static func leftWidth(
        totalWidth: CGFloat,
        leftFraction: Double,
        minLeftWidth: CGFloat = minTableWidth,
        minRightWidth: CGFloat = minPreviewWidth
    ) -> CGFloat {
        guard totalWidth.isFinite, totalWidth > 0 else { return 0 }
        let candidate = totalWidth * CGFloat(normalizedFraction(leftFraction))
        return clampedLeftWidth(
            totalWidth: totalWidth,
            proposed: candidate,
            minLeftWidth: minLeftWidth,
            minRightWidth: minRightWidth
        )
    }

    static func updatedFraction(
        totalWidth: CGFloat,
        startFraction: Double,
        translation: CGFloat,
        minLeftWidth: CGFloat = minTableWidth,
        minRightWidth: CGFloat = minPreviewWidth
    ) -> Double {
        guard totalWidth.isFinite, totalWidth > 0 else { return normalizedFraction(startFraction) }
        let startLeft = leftWidth(
            totalWidth: totalWidth,
            leftFraction: startFraction,
            minLeftWidth: minLeftWidth,
            minRightWidth: minRightWidth
        )
        let updatedLeft = clampedLeftWidth(
            totalWidth: totalWidth,
            proposed: startLeft + translation,
            minLeftWidth: minLeftWidth,
            minRightWidth: minRightWidth
        )
        return normalizedFraction(Double(updatedLeft / totalWidth))
    }

    private static func clampedLeftWidth(
        totalWidth: CGFloat,
        proposed: CGFloat,
        minLeftWidth: CGFloat,
        minRightWidth: CGFloat
    ) -> CGFloat {
        let minimumLeft = min(max(0, minLeftWidth), totalWidth)
        let maximumLeft = max(minimumLeft, totalWidth - max(0, minRightWidth))
        return min(max(proposed, minimumLeft), maximumLeft)
    }

    private static func normalizedFraction(_ fraction: Double) -> Double {
        guard fraction.isFinite else { return defaultLeftFraction }
        return min(1, max(0, fraction))
    }
}

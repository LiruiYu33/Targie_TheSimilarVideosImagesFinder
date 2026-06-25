// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

import CryptoKit
import Foundation

struct ThumbnailStore: Sendable {
    static let shared = ThumbnailStore(directoryURL: defaultDirectoryURL())

    let directoryURL: URL

    func persist(_ data: Data, sourceURL: URL, modifiedAt: Date?) throws -> URL {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let pathKey = pathKey(for: sourceURL)
        let destination = destinationURL(pathKey: pathKey, modifiedAt: modifiedAt)
        // Remove every thumbnail for this source file that differs from the
        // current modification time — those are stale because the file changed.
        if let existing = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) {
            for url in existing where url.lastPathComponent.hasPrefix("\(pathKey)_") && url != destination {
                try? FileManager.default.removeItem(at: url)
            }
        }
        if !FileManager.default.fileExists(atPath: destination.path) {
            try data.write(to: destination, options: .atomic)
        }
        ThumbnailDataCache.shared.insert(data, for: destination)
        return destination
    }

    /// Returns the persisted thumbnail URL for `sourceURL` if one already exists
    /// on disk, without generating anything. Lets scanners skip the expensive
    /// thumbnail generation (video frame decode / image downscale) on re-scan.
    func existingThumbnailURL(for sourceURL: URL, modifiedAt: Date?) -> URL? {
        let expected = destinationURL(pathKey: pathKey(for: sourceURL), modifiedAt: modifiedAt)
        return FileManager.default.fileExists(atPath: expected.path) ? expected : nil
    }

    /// Stable hash of the canonical source path — used as a prefix so we can
    /// find (and clean up) all thumbnails belonging to the same file.
    private func pathKey(for sourceURL: URL) -> String {
        SHA256.hash(data: Data(sourceURL.standardizedFileURL.path.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// Filename: `{pathKey}_{modifiedKey}.jpg`.  The modifiedKey changes when
    /// the file's content-modification date changes, so a new thumbnail gets
    /// a different name and `persist` cleans up the previous one.
    private func destinationURL(pathKey: String, modifiedAt: Date?) -> URL {
        let modifiedKey = SHA256.hash(data: Data("\(modifiedAt?.timeIntervalSince1970 ?? 0)".utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directoryURL.appendingPathComponent("\(pathKey)_\(modifiedKey).jpg")
    }

    /// Total size of cached thumbnail files, in bytes.
    func totalSize() -> Int64 {
        guard FileManager.default.fileExists(atPath: directoryURL.path),
              let contents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey])
        else { return 0 }
        return contents.filter { $0.pathExtension == "jpg" }.reduce(0) { total, url in
            total + Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    /// Number of cached thumbnails currently on disk.
    func count() -> Int {
        guard FileManager.default.fileExists(atPath: directoryURL.path),
              let contents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        else { return 0 }
        return contents.filter { $0.pathExtension == "jpg" }.count
    }

    /// Removes every cached thumbnail from disk and the in-memory cache.
    func clearAll() throws {
        ThumbnailDataCache.shared.removeAll()
        guard FileManager.default.fileExists(atPath: directoryURL.path) else { return }
        let contents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        for url in contents where url.pathExtension == "jpg" {
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func data(at url: URL) -> Data? {
        ThumbnailDataCache.shared.data(at: url)
    }

    private static func defaultDirectoryURL() -> URL {
        let base = (try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Targie", isDirectory: true)
            .appendingPathComponent("thumbnails", isDirectory: true)
    }
}

private final class ThumbnailDataCache: @unchecked Sendable {
    static let shared = ThumbnailDataCache()

    private let cache = NSCache<NSURL, NSData>()

    private init() {
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    func insert(_ data: Data, for url: URL) {
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    func data(at url: URL) -> Data? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached as Data
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        insert(data, for: url)
        return data
    }
}

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
        let identity = "\(sourceURL.standardizedFileURL.path)|\(modifiedAt?.timeIntervalSince1970 ?? 0)"
        let digest = SHA256.hash(data: Data(identity.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let destination = directoryURL.appendingPathComponent("\(digest).jpg")
        if !FileManager.default.fileExists(atPath: destination.path) {
            try data.write(to: destination, options: .atomic)
        }
        ThumbnailDataCache.shared.insert(data, for: destination)
        return destination
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

    func data(at url: URL) -> Data? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached as Data
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        insert(data, for: url)
        return data
    }
}

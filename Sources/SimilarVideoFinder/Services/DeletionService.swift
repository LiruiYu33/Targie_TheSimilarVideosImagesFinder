import AppKit
import Foundation

enum DeletionMode: Sendable {
    case trash
    case permanent
}

enum DeletionError: Error, Equatable {
    case fileMissing
    case operationFailed(String)

    func localizedDescription(_ language: AppLanguage) -> String {
        switch self {
        case .fileMissing: L10n.fileMissing(language)
        case .operationFailed(let message): L10n.deletionFailed(message, language)
        }
    }
}

@MainActor
protocol DeletionServicing: AnyObject {
    func delete(url: URL, mode: DeletionMode) async throws
    func reveal(_ url: URL)
    func open(_ url: URL)
}

@MainActor
final class DeletionService: DeletionServicing {
    func delete(url: URL, mode: DeletionMode) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw DeletionError.fileMissing }
        do {
            switch mode {
            case .trash:
                _ = try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            case .permanent:
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            throw DeletionError.operationFailed(error.localizedDescription)
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

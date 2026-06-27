// Targie - Find similar media on macOS.
// Copyright (C) 2026 Lirui Yu

enum BrowseRowSelectionIntent: Equatable, Sendable {
    case replace
    case toggle
    case extend

    static func make(isCommandPressed: Bool, isShiftPressed: Bool) -> BrowseRowSelectionIntent {
        if isShiftPressed { return .extend }
        if isCommandPressed { return .toggle }
        return .replace
    }
}

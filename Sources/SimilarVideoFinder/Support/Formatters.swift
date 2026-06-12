import Foundation

enum DisplayFormatters {
    static func fileSize(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: value)
    }

    static func duration(_ seconds: Double, language: AppLanguage = .defaultLanguage) -> String {
        guard seconds.isFinite, seconds >= 0 else { return L10n.unknown(language) }
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let remaining = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, remaining)
            : String(format: "%02d:%02d", minutes, remaining)
    }

    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}

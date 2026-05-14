import Foundation

/// Человекочитаемый размер файла (KB / MB / GB).
public enum ByteSizeFormatting: Sendable {
    public static func string(forByteCount bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

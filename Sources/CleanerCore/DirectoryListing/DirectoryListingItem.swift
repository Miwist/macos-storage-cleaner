import Foundation

/// Элемент первого уровня в выбранной папке.
/// Хранит путь как `String`, чтобы структура была `Sendable` при сборке Swift 5.9 / строгом concurrency в CI.
public struct DirectoryListingItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    /// Абсолютный путь в файловой системе (как у `URL.standardizedFileURL.path`).
    public let path: String
    public let isDirectory: Bool
    /// Для файлов — размер в байтах; для папок без рекурсивного обхода — `nil` (в UI показывается «—»).
    public let sizeBytes: Int64?
    /// Эвристическая метка для подсветки в UI (см. `PathSafetyClassifier`).
    public let safetyKind: StoragePathSafetyKind

    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        sizeBytes: Int64?,
        safetyKind: StoragePathSafetyKind = .neutral
    ) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.sizeBytes = sizeBytes
        self.safetyKind = safetyKind
        self.id = path
    }

    /// Удобство для UI и отладки (создаётся на лету).
    public var fileURL: URL {
        URL(fileURLWithPath: path, isDirectory: isDirectory)
    }

    public func sizeDisplayString() -> String {
        if isDirectory {
            return ByteSizeFormatting.string(forOptionalByteCount: sizeBytes, missing: "оценка недоступна")
        }
        guard let bytes = sizeBytes else { return "—" }
        return ByteSizeFormatting.string(forByteCount: bytes)
    }
}

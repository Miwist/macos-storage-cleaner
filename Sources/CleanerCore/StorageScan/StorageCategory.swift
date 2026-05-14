import Foundation

/// Логическая категория занятого места (как в «Хранилище» macOS). Названия для пользователя задаются в UI.
public enum StorageCategory: String, Sendable, CaseIterable, Identifiable, Codable {
    case applications
    case downloads
    case documents
    case desktop
    case pictures
    case movies
    case music
    case caches
    case developerTools
    case trash

    public var id: String { rawValue }
}

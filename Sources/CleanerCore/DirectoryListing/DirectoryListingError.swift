import Foundation

/// Ошибки поверхностного листинга каталога (пользовательские тексты на русском).
/// В ассоциированных значениях используется `String` (путь), а не `URL`, чтобы тип был `Sendable` на всех версиях Swift в CI.
public enum DirectoryListingError: Error, LocalizedError, Sendable {
    case notDirectory(path: String)
    case accessDenied(path: String)
    case enumerationFailed(path: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .notDirectory(let path):
            "Выбранный объект не является папкой: \(path)"
        case .accessDenied(let path):
            "Нет доступа к содержимому папки. Для каталогов вроде «Документы» или «Загрузки» обычно достаточно прав пользователя; для системных путей может понадобиться «Полный доступ к диску» в настройках macOS.\n\(path)"
        case .enumerationFailed(let path, let reason):
            "Не удалось прочитать содержимое папки.\n\(reason)\n\(path)"
        }
    }
}

import Foundation

/// Ошибки поверхностного листинга каталога (тексты для пользователя на русском, без лишнего жаргона).
public enum DirectoryListingError: Error, LocalizedError, Sendable {
    case notDirectory(path: String)
    case accessDenied(path: String)
    case enumerationFailed(path: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .notDirectory:
            "Это не папка, а другой тип файла. Выберите обычную папку."
        case .accessDenied:
            "macOS не дал открыть эту папку. Чаще всего помогает добавить приложение в список «Полный доступ к диску» в разделе «Конфиденциальность и безопасность» системных настроек."
        case .enumerationFailed:
            "Не удалось прочитать содержимое папки. Попробуйте другую папку или повторите позже."
        }
    }
}

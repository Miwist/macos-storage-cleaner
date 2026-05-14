import Foundation

/// Разрешённые корни и блокировки для сценариев быстрой очистки (MVP #6).
public enum QuickCleanPathPolicy: Sendable {
    /// Корни, из которых разрешены операции быстрой очистки (после `standardizedFileURL`).
    public static func allowedCategoryRoots(home: URL) -> [URL] {
        let h = home.standardizedFileURL
        return [
            h.appendingPathComponent("Library/Caches", isDirectory: true),
            h.appendingPathComponent(".Trash", isDirectory: true),
            FileManager.default.temporaryDirectory.standardizedFileURL,
        ]
    }

    /// `true`, если путь находится строго внутри или равен одному из разрешённых корней категорий.
    public static func isPathUnderAllowedQuickCleanHierarchy(path: String, home: URL) -> Bool {
        let p = URL(fileURLWithPath: path).standardizedFileURL
        for root in allowedCategoryRoots(home: home) {
            let r = root.standardizedFileURL
            if p.path == r.path { return true }
            let prefix = r.path.hasSuffix("/") ? r.path : r.path + "/"
            if p.path.hasPrefix(prefix) { return true }
        }
        return false
    }

    /// Блокирует заведомо опасные абсолютные пути (системные тома, связки и т.п.).
    public static func isGloballyForbiddenForUserInitiatedTrash(path: String, home: URL) -> Bool {
        let normalized = URL(fileURLWithPath: path).standardizedFileURL.path
        let homePath = home.standardizedFileURL.path
        if normalized.hasPrefix("/System") { return true }
        if normalized.contains("/Library/Keychains/") { return true }
        if normalized.hasPrefix("/private/var/db") { return true }
        if normalized == "/private/var/db" { return true }
        if normalized.hasPrefix("/private/etc") || normalized == "/etc" || normalized.hasPrefix("/etc/") { return true }
        if normalized.hasPrefix("/usr/") || normalized == "/usr" { return true }
        if normalized.hasPrefix("/bin") || normalized == "/bin" { return true }
        if normalized.hasPrefix("/sbin") || normalized == "/sbin" { return true }
        if normalized.hasPrefix("/Library/"), !normalized.hasPrefix(homePath + "/Library/") { return true }
        return false
    }
}

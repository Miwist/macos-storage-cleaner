import Foundation

/// Правила «важно» / «кандидат на относительно безопасную очистку» для подсветки в списках.
/// Удаление и быстрая очистка дополнительно ограничиваются отдельными политиками (`QuickCleanPathPolicy`).
public enum PathSafetyClassifier: Sendable {
    public static func classify(path inputPath: String) -> StoragePathSafetyKind {
        let path = URL(fileURLWithPath: inputPath).standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path

        if isImportant(path: path, home: home) { return .important }
        if isRelativelySafeCandidate(path: path, home: home) { return .relativelySafeCleanupCandidate }
        return .neutral
    }

    private static func isImportant(path: String, home: String) -> Bool {
        if path.contains(".app/") {
            if path.contains("/Applications/") || path.contains("/System/Applications/") { return true }
        }
        if path.hasPrefix("/System") { return true }
        if path.contains("/Library/Keychains/") { return true }
        if path.hasPrefix("/private/var/db") { return true }
        if path == "/private/var/db" { return true }
        if path.hasPrefix("/private/etc") || path == "/etc" || path.hasPrefix("/etc/") { return true }

        let protectedHomeDirs = ["Documents", "Desktop", "Movies", "Music", "Pictures", "Public"]
        for leaf in protectedHomeDirs {
            let prefix = home + "/" + leaf
            if path == prefix || path.hasPrefix(prefix + "/") { return true }
        }

        return false
    }

    private static func isRelativelySafeCandidate(path: String, home: String) -> Bool {
        let caches = home + "/Library/Caches"
        if path == caches || path.hasPrefix(caches + "/") { return true }

        let logs = home + "/Library/Logs"
        if path == logs || path.hasPrefix(logs + "/") { return true }

        let tempRoot = FileManager.default.temporaryDirectory.standardizedFileURL.path
        if path == tempRoot || path.hasPrefix(tempRoot + "/") { return true }

        return false
    }
}

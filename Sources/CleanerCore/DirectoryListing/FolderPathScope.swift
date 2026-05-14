import Foundation

/// Проверки путей при навигации внутри выбранного корня (без выхода за пределы через симлинки).
public enum FolderPathScope: Sendable {
    public static func resolvingStandardDirectory(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    /// `true`, если `location` совпадает с корнем или лежит внутри него в дереве каталогов.
    public static func isLocationInsideRoot(root: URL, location: URL) -> Bool {
        let r = resolvingStandardDirectory(root).path
        let l = resolvingStandardDirectory(location).path
        if l == r { return true }
        if r == "/" { return l.hasPrefix("/") }
        let prefix = r.hasSuffix("/") ? r : r + "/"
        return l.hasPrefix(prefix)
    }
}

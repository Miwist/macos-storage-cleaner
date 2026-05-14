import Foundation

extension StorageCategory {
    /// Типичный корень категории на диске пользователя (для перехода «внутрь» из обзора).
    public func typicalRootURL(home: URL = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL) -> URL {
        switch self {
        case .applications:
            return URL(fileURLWithPath: "/Applications", isDirectory: true)
        case .downloads:
            return home.appendingPathComponent("Downloads", isDirectory: true)
        case .documents:
            return home.appendingPathComponent("Documents", isDirectory: true)
        case .desktop:
            return home.appendingPathComponent("Desktop", isDirectory: true)
        case .pictures:
            return home.appendingPathComponent("Pictures", isDirectory: true)
        case .movies:
            return home.appendingPathComponent("Movies", isDirectory: true)
        case .music:
            return home.appendingPathComponent("Music", isDirectory: true)
        case .caches:
            return home.appendingPathComponent("Library/Caches", isDirectory: true)
        case .developerTools:
            return home.appendingPathComponent("Library/Developer", isDirectory: true)
        case .trash:
            return home.appendingPathComponent(".Trash", isDirectory: true)
        }
    }
}

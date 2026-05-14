import Foundation

/// Перенос в корзину из браузера «Память» внутри выбранного корня (не быстрая очистка).
public enum FolderBrowserTrash: Sendable {
    public enum Error: Swift.Error, Sendable, LocalizedError {
        case pathOutsideRoot
        case pathForbidden
        case trashFailed(String)

        public var errorDescription: String? {
            switch self {
            case .pathOutsideRoot:
                return "Этот объект находится вне текущего просмотра — в корзину его не отправляем."
            case .pathForbidden:
                return "Этот путь мы намеренно не трогаем из соображений безопасности."
            case .trashFailed(let reason):
                return reason
            }
        }
    }

    /// Перемещает файл или папку в корзину пользователя, если путь разрешён политикой.
    public static func moveToTrash(itemPath: String, root: URL, home: URL) throws {
        let resolved = URL(fileURLWithPath: itemPath).standardizedFileURL.resolvingSymlinksInPath()

        if QuickCleanPathPolicy.isGloballyForbiddenForUserInitiatedTrash(path: resolved.path, home: home) {
            throw Error.pathForbidden
        }
        guard FolderPathScope.isLocationInsideRoot(root: root, location: resolved) else {
            throw Error.pathOutsideRoot
        }

        do {
            var resulting: NSURL?
            try FileManager.default.trashItem(at: resolved, resultingItemURL: &resulting)
        } catch {
            throw Error.trashFailed(error.localizedDescription)
        }
    }
}

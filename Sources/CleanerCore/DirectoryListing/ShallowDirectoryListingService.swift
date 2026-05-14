import Foundation

/// Список только прямых вложений выбранной папки. Обход выполняется вне вызывающего актора (см. `Task.detached`).
public protocol ShallowDirectoryListing: Sendable {
    func listDirectChildren(of directory: URL) async throws -> [DirectoryListingItem]
}

public struct ShallowDirectoryListingService: ShallowDirectoryListing, Sendable {
    public init() {}

    public func listDirectChildren(of directory: URL) async throws -> [DirectoryListingItem] {
        let path = directory.standardizedFileURL.path
        return try await Task.detached(priority: .userInitiated) {
            try Self.performList(directoryPath: path)
        }.value
    }

    nonisolated private static func performList(directoryPath: String) throws -> [DirectoryListingItem] {
        let directory = URL(fileURLWithPath: directoryPath, isDirectory: true)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            throw DirectoryListingError.notDirectory(path: directoryPath)
        }

        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .isPackageKey,
                    .fileSizeKey,
                ],
                options: []
            )
        } catch {
            throw Self.mapEnumerationError(directoryPath: directoryPath, error: error)
        }

        var items: [DirectoryListingItem] = []
        items.reserveCapacity(urls.count)

        for url in urls {
            do {
                let values = try url.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .isPackageKey,
                    .fileSizeKey,
                ])
                let isPackage = values.isPackage ?? false
                let isDirectory = (values.isDirectory ?? false) || isPackage
                let isRegular = values.isRegularFile ?? false
                let itemPath = url.standardizedFileURL.path

                if isDirectory {
                    items.append(DirectoryListingItem(name: url.lastPathComponent, path: itemPath, isDirectory: true, sizeBytes: nil))
                } else if isRegular {
                    let size = Int64(values.fileSize ?? 0)
                    items.append(DirectoryListingItem(name: url.lastPathComponent, path: itemPath, isDirectory: false, sizeBytes: size))
                } else {
                    // Симлинки и прочие: показываем строку без размера файла.
                    items.append(DirectoryListingItem(name: url.lastPathComponent, path: itemPath, isDirectory: false, sizeBytes: nil))
                }
            } catch {
                throw DirectoryListingError.enumerationFailed(
                    path: directoryPath,
                    reason: "Не удалось прочитать свойства: \(url.lastPathComponent) — \(error.localizedDescription)"
                )
            }
        }

        return items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory && !rhs.isDirectory }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    nonisolated private static func mapEnumerationError(directoryPath: String, error: Error) -> DirectoryListingError {
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain {
            switch ns.code {
            case NSFileReadNoPermissionError:
                return .accessDenied(path: directoryPath)
            default:
                break
            }
        }
        return .enumerationFailed(path: directoryPath, reason: error.localizedDescription)
    }
}

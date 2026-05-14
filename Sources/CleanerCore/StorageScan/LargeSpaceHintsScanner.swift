import Foundation

/// Крупная папка или файл, который стоит показать пользователю как кандидат на освобождение места.
public struct LargeSpaceCandidate: Sendable, Identifiable, Equatable {
    public let path: String
    public let displayName: String
    public let byteSize: Int64
    public let safetyKind: StoragePathSafetyKind
    public let isDirectory: Bool

    public var id: String { path }

    public init(path: String, displayName: String, byteSize: Int64, safetyKind: StoragePathSafetyKind, isDirectory: Bool) {
        self.path = path
        self.displayName = displayName
        self.byteSize = byteSize
        self.safetyKind = safetyKind
        self.isDirectory = isDirectory
    }
}

/// Поиск крупных вложенных объектов в типичных местах (загрузки, рабочий стол, кэши).
public enum LargeSpaceHintsScanner: Sendable {
    private static let minimumBytes: Int64 = 80 * 1024 * 1024
    private static let maxHints = 24

    public static func findCandidates() async -> [LargeSpaceCandidate] {
        await Task.detached(priority: .utility) {
            await asyncCollectCandidates()
        }.value
    }

    private static func asyncCollectCandidates() async -> [LargeSpaceCandidate] {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let roots: [URL] = [
            home.appendingPathComponent("Downloads", isDirectory: true),
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Movies", isDirectory: true),
            home.appendingPathComponent("Library/Caches", isDirectory: true),
        ]

        var collected: [LargeSpaceCandidate] = []

        for root in roots {
            await collectLargeChildren(of: root, into: &collected)
            if collected.count >= maxHints { break }
        }

        return collected
            .sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
                return $0.byteSize > $1.byteSize
            }
            .prefix(maxHints)
            .map { $0 }
    }

    private static func collectLargeChildren(of directory: URL, into collected: inout [LargeSpaceCandidate]) async {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return
        }

        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isPackageKey, .fileSizeKey],
                options: []
            )
        } catch {
            return
        }

        for url in urls {
            if collected.count >= maxHints { return }

            let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
            let values = try? resolved.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isPackageKey, .fileSizeKey])
            let isPackage = values?.isPackage ?? false
            let isDirectory = (values?.isDirectory ?? false) || isPackage

            if isDirectory {
                let opts = DirectoryByteCounter.Options(maxDepth: 8, maxVisitedNodes: 40_000)
                let bytes = (try? await DirectoryByteCounter.totalBytes(at: resolved, options: opts)) ?? 0
                if bytes >= minimumBytes {
                    let name = resolved.lastPathComponent
                    let kind = PathSafetyClassifier.classify(path: resolved.path)
                    collected.append(
                        LargeSpaceCandidate(
                            path: resolved.path,
                            displayName: name,
                            byteSize: bytes,
                            safetyKind: kind,
                            isDirectory: true
                        )
                    )
                }
            } else if values?.isRegularFile == true {
                let bytes = Int64(values?.fileSize ?? 0)
                if bytes >= minimumBytes {
                    let kind = PathSafetyClassifier.classify(path: resolved.path)
                    collected.append(
                        LargeSpaceCandidate(
                            path: resolved.path,
                            displayName: resolved.lastPathComponent,
                            byteSize: bytes,
                            safetyKind: kind,
                            isDirectory: false
                        )
                    )
                }
            }
        }
    }
}

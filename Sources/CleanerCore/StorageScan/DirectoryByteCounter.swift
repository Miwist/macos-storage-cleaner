import Foundation

/// Рекурсивный подсчёт размера каталога с ограничениями по глубине и числу посещений (без SwiftUI).
public enum DirectoryByteCounter: Sendable {
    public struct Options: Sendable {
        /// Глубина от корня: 0 — только файлы в корне, для вложенных папок увеличивается.
        public var maxDepth: Int
        /// Защита от слишком долгого обхода.
        public var maxVisitedNodes: Int

        public init(maxDepth: Int, maxVisitedNodes: Int = 100_000) {
            self.maxDepth = maxDepth
            self.maxVisitedNodes = maxVisitedNodes
        }
    }

    /// Суммарный размер файлов под `root`. Симлинки на каталоги не обходятся повторно (по каноническому пути).
    public static func totalBytes(at root: URL, options: Options) async throws -> Int64 {
        let rootURL = root.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = rootURL.path
        return try await Task.detached(priority: .utility) {
            try syncTotalBytes(root: rootURL, rootPath: rootPath, options: options)
        }.value
    }

    nonisolated private static func syncTotalBytes(root: URL, rootPath: String, options: Options) throws -> Int64 {
        var visitedDirectoryCanonical = Set<String>()
        var visitCounter = 0
        return try walkDirectory(
            root,
            rootPath: rootPath,
            depth: 0,
            options: options,
            visited: &visitedDirectoryCanonical,
            visitCounter: &visitCounter
        )
    }

    nonisolated private static func walkDirectory(
        _ directory: URL,
        rootPath: String,
        depth: Int,
        options: Options,
        visited: inout Set<String>,
        visitCounter: inout Int
    ) throws -> Int64 {
        visitCounter += 1
        if visitCounter > options.maxVisitedNodes { return 0 }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return 0
        }

        let canonical = directory.standardizedFileURL.resolvingSymlinksInPath().path
        guard canonical == rootPath || canonical.hasPrefix(rootPath + "/") else {
            return 0
        }

        if visited.contains(canonical) { return 0 }
        visited.insert(canonical)

        if let allocated = try allocatedDirectoryByteSize(directory) {
            return allocated
        }

        let children: [URL]
        do {
            children = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isPackageKey, .fileSizeKey],
                options: [.skipsPackageDescendants]
            )
        } catch {
            throw error
        }

        var sum: Int64 = 0
        for url in children {
            visitCounter += 1
            if visitCounter > options.maxVisitedNodes { break }

            let childCanonical = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard childCanonical == rootPath || childCanonical.hasPrefix(rootPath + "/") else {
                continue
            }

            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isPackageKey, .fileSizeKey])
            let isPackage = values.isPackage ?? false
            let isDirectory = (values.isDirectory ?? false) || isPackage
            if isDirectory {
                if depth >= options.maxDepth {
                    continue
                }
                sum += try walkDirectory(
                    url,
                    rootPath: rootPath,
                    depth: depth + 1,
                    options: options,
                    visited: &visited,
                    visitCounter: &visitCounter
                )
            } else if values.isRegularFile == true {
                sum += Int64(values.fileSize ?? 0)
            }
        }

        return sum
    }

    /// Если система отдаёт готовый размер папки (часто для `.app`), используем его и не уходим внутрь.
    nonisolated private static func allocatedDirectoryByteSize(_ url: URL) throws -> Int64? {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey])
        guard values.isDirectory == true else { return nil }
        if let n = values.totalFileAllocatedSize {
            return Int64(n)
        }
        return nil
    }
}

import Foundation

/// Планирование и выполнение быстрой очистки вне главного потока UI.
public struct QuickCleanService: Sendable {
    public init() {}

    public func makePlan(categories: Set<QuickCleanCategory>) async throws -> QuickCleanPlan {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        var lines: [QuickCleanPlanLine] = []
        lines.reserveCapacity(categories.count)

        if categories.contains(.userCaches) {
            let root = home.appendingPathComponent("Library/Caches", isDirectory: true)
            let (targets, knownFileBytes) = try await Self.listPlanTargets(of: root)
            lines.append(
                QuickCleanPlanLine(
                    category: .userCaches,
                    rootPath: root.path,
                    topLevelEntryCount: targets.count,
                    knownFileBytes: knownFileBytes,
                    targets: targets
                )
            )
        }

        if categories.contains(.userTemporaryFiles) {
            let root = FileManager.default.temporaryDirectory.standardizedFileURL
            let (targets, knownFileBytes) = try await Self.listPlanTargets(of: root)
            lines.append(
                QuickCleanPlanLine(
                    category: .userTemporaryFiles,
                    rootPath: root.path,
                    topLevelEntryCount: targets.count,
                    knownFileBytes: knownFileBytes,
                    targets: targets
                )
            )
        }

        if categories.contains(.emptyTrashPermanently) {
            let root = home.appendingPathComponent(".Trash", isDirectory: true)
            let (targets, knownFileBytes) = try await Self.listPlanTargets(of: root)
            lines.append(
                QuickCleanPlanLine(
                    category: .emptyTrashPermanently,
                    rootPath: root.path,
                    topLevelEntryCount: targets.count,
                    knownFileBytes: knownFileBytes,
                    targets: targets
                )
            )
        }

        return QuickCleanPlan(lines: lines.sorted { $0.category.rawValue < $1.category.rawValue })
    }

    public func execute(selection: QuickCleanExecutionSelection) async -> [QuickCleanRunReport] {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        var reports: [QuickCleanRunReport] = []

        if let paths = selection.caches {
            let urls = paths.map { URL(fileURLWithPath: $0) }
            let r = await Self.movePathsToTrash(urls: urls, home: home)
            reports.append(QuickCleanRunReport(category: .userCaches, entries: r))
        }

        if let paths = selection.temporaryFiles {
            let urls = paths.map { URL(fileURLWithPath: $0) }
            let r = await Self.movePathsToTrash(urls: urls, home: home)
            reports.append(QuickCleanRunReport(category: .userTemporaryFiles, entries: r))
        }

        if let paths = selection.trash, selection.permanentlyEmptyTrash {
            let urls = paths.map { URL(fileURLWithPath: $0) }
            let r = await Self.permanentRemovePaths(urls: urls, trashRoot: home.appendingPathComponent(".Trash", isDirectory: true), home: home)
            reports.append(QuickCleanRunReport(category: .emptyTrashPermanently, entries: r))
        }

        return reports
    }

    private static func listPlanTargets(of directory: URL) async throws -> ([QuickCleanPlanTarget], Int64) {
        let path = directory.standardizedFileURL.path
        return try await Task.detached(priority: .utility) {
            try listPlanTargetsSync(directoryPath: path)
        }.value
    }

    nonisolated private static func listPlanTargetsSync(directoryPath: String) throws -> ([QuickCleanPlanTarget], Int64) {
        let directory = URL(fileURLWithPath: directoryPath, isDirectory: true)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return ([], 0)
        }

        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .fileSizeKey],
                options: []
            )
        } catch {
            throw error
        }

        var targets: [QuickCleanPlanTarget] = []
        targets.reserveCapacity(urls.count)
        var knownFileBytes: Int64 = 0

        for url in urls {
            let itemPath = url.standardizedFileURL.path
            let values = try url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey,
                .isPackageKey,
                .fileSizeKey,
                .totalFileAllocatedSizeKey,
            ])
            let isPackage = values.isPackage ?? false
            let isDirectory = (values.isDirectory ?? false) || isPackage
            let isRegular = values.isRegularFile ?? false
            let name = url.lastPathComponent

            if isDirectory {
                let allocated = values.totalFileAllocatedSize.map { Int64($0) }
                targets.append(QuickCleanPlanTarget(path: itemPath, displayName: name, estimatedBytes: allocated, isDirectory: true))
            } else if isRegular {
                let size = Int64(values.fileSize ?? 0)
                knownFileBytes += size
                targets.append(QuickCleanPlanTarget(path: itemPath, displayName: name, estimatedBytes: size, isDirectory: false))
            } else {
                targets.append(QuickCleanPlanTarget(path: itemPath, displayName: name, estimatedBytes: nil, isDirectory: false))
            }
        }

        targets.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory && !rhs.isDirectory }
            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
        return (targets, knownFileBytes)
    }

    private static func movePathsToTrash(urls: [URL], home: URL) async -> [QuickCleanEntryResult] {
        await Task.detached(priority: .userInitiated) {
            Self.movePathsToTrashSync(urls: urls, home: home)
        }.value
    }

    nonisolated private static func movePathsToTrashSync(urls: [URL], home: URL) -> [QuickCleanEntryResult] {
        var results: [QuickCleanEntryResult] = []
        results.reserveCapacity(urls.count)

        for url in urls {
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
            let path = resolved.path

            if QuickCleanPathPolicy.isGloballyForbiddenForUserInitiatedTrash(path: path, home: home) {
                results.append(
                    QuickCleanEntryResult(
                        path: path,
                        outcome: .skipped(reason: "Этот объект мы намеренно не трогаем из соображений безопасности.")
                    )
                )
                continue
            }
            if !QuickCleanPathPolicy.isPathUnderAllowedQuickCleanHierarchy(path: path, home: home) {
                results.append(
                    QuickCleanEntryResult(
                        path: path,
                        outcome: .skipped(reason: "Этот объект не входит в разрешённые сценарии быстрой очистки.")
                    )
                )
                continue
            }

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: resolved.path, isDirectory: &isDir) else {
                results.append(QuickCleanEntryResult(path: path, outcome: .skipped(reason: "Объект уже отсутствует на диске.")))
                continue
            }

            do {
                var resulting: NSURL?
                try FileManager.default.trashItem(at: resolved, resultingItemURL: &resulting)
                results.append(QuickCleanEntryResult(path: path, outcome: .movedToTrash))
            } catch {
                results.append(QuickCleanEntryResult(path: path, outcome: .skipped(reason: error.localizedDescription)))
            }
        }

        return results
    }

    private static func permanentRemovePaths(urls: [URL], trashRoot: URL, home: URL) async -> [QuickCleanEntryResult] {
        await Task.detached(priority: .userInitiated) {
            Self.permanentRemovePathsSync(urls: urls, trashRoot: trashRoot, home: home)
        }.value
    }

    nonisolated private static func permanentRemovePathsSync(urls: [URL], trashRoot: URL, home: URL) -> [QuickCleanEntryResult] {
        let trash = trashRoot.standardizedFileURL
        let trashPrefix = trash.path.hasSuffix("/") ? trash.path : trash.path + "/"

        var results: [QuickCleanEntryResult] = []
        results.reserveCapacity(urls.count)

        for url in urls {
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
            let path = resolved.path

            if QuickCleanPathPolicy.isGloballyForbiddenForUserInitiatedTrash(path: path, home: home) {
                results.append(
                    QuickCleanEntryResult(
                        path: path,
                        outcome: .skipped(reason: "Этот объект мы намеренно не трогаем из соображений безопасности.")
                    )
                )
                continue
            }
            guard path == trash.path || path.hasPrefix(trashPrefix) else {
                results.append(
                    QuickCleanEntryResult(path: path, outcome: .skipped(reason: "Похоже, это не содержимое корзины — пропускаем."))
                )
                continue
            }

            do {
                try FileManager.default.removeItem(at: resolved)
                results.append(QuickCleanEntryResult(path: path, outcome: .permanentlyRemoved))
            } catch {
                results.append(QuickCleanEntryResult(path: path, outcome: .skipped(reason: error.localizedDescription)))
            }
        }

        return results
    }
}

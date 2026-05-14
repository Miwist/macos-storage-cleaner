import Foundation

/// Оценка занятого места по типичным категориям (в духе «Хранилище» macOS). Работает в пределах доступных пользователю путей.
public struct VolumeStorageScanner: Sendable {
    public init() {}

    public func scanAllCategories(
        progressHandler: (@Sendable (VolumeStorageScanProgress) -> Void)? = nil
    ) async throws -> [StorageCategoryTotal] {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL

        let phases: [(StorageCategory, URL, DirectoryByteCounter.Options)] = [
            (.applications, URL(fileURLWithPath: "/Applications", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 3, maxVisitedNodes: 60_000)),
            (.downloads, home.appendingPathComponent("Downloads", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 14, maxVisitedNodes: 120_000)),
            (.documents, home.appendingPathComponent("Documents", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 14, maxVisitedNodes: 120_000)),
            (.desktop, home.appendingPathComponent("Desktop", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 12, maxVisitedNodes: 100_000)),
            (.pictures, home.appendingPathComponent("Pictures", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 12, maxVisitedNodes: 100_000)),
            (.movies, home.appendingPathComponent("Movies", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 12, maxVisitedNodes: 100_000)),
            (.music, home.appendingPathComponent("Music", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 10, maxVisitedNodes: 80_000)),
            (.caches, home.appendingPathComponent("Library/Caches", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 8, maxVisitedNodes: 150_000)),
            (.developerTools, home.appendingPathComponent("Library/Developer", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 6, maxVisitedNodes: 120_000)),
            (.trash, home.appendingPathComponent(".Trash", isDirectory: true), DirectoryByteCounter.Options(maxDepth: 6, maxVisitedNodes: 40_000)),
        ]

        let totalPhases = phases.count
        var results: [StorageCategoryTotal] = []
        results.reserveCapacity(totalPhases)

        for (index, phase) in phases.enumerated() {
            let (category, url, options) = phase
            let fractionBefore = Double(index) / Double(totalPhases)
            progressHandler?(
                VolumeStorageScanProgress(
                    completedPhaseIndex: index,
                    totalPhases: totalPhases,
                    currentCategory: category,
                    overallFraction: fractionBefore
                )
            )

            let exists = FileManager.default.fileExists(atPath: url.path)
            let bytes: Int64
            if exists {
                bytes = (try? await DirectoryByteCounter.totalBytes(at: url, options: options)) ?? 0
            } else {
                bytes = 0
            }

            results.append(StorageCategoryTotal(category: category, bytes: bytes))

            let fractionAfter = Double(index + 1) / Double(totalPhases)
            progressHandler?(
                VolumeStorageScanProgress(
                    completedPhaseIndex: index + 1,
                    totalPhases: totalPhases,
                    currentCategory: category,
                    overallFraction: fractionAfter
                )
            )
        }

        return results
    }
}

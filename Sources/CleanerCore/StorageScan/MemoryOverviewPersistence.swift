import Foundation

/// Сохранение снимка оценки «Память» и грубой статистики быстрой очистки (UserDefaults).
public enum MemoryOverviewPersistence: Sendable {
    private static let snapshotKey = "MacosStorageCleaner.memoryOverview.snapshot.v1"
    private static let cleanupKey = "MacosStorageCleaner.memoryOverview.cleanup.v1"

    public struct Snapshot: Sendable, Equatable, Codable {
        public var scannedAt: Date
        public var categoryTotals: [StorageCategoryTotal]

        public init(scannedAt: Date, categoryTotals: [StorageCategoryTotal]) {
            self.scannedAt = scannedAt
            self.categoryTotals = categoryTotals
        }
    }

    public struct CleanupSummary: Sendable, Equatable, Codable {
        public var lastCleanupAt: Date
        /// Оценка по плану (известные размеры целей); реальное освобождение может отличаться.
        public var lastFreedBytesEstimate: Int64
        public var lastAffectedItemCount: Int
        public var cumulativeFreedBytesEstimate: Int64

        public init(
            lastCleanupAt: Date,
            lastFreedBytesEstimate: Int64,
            lastAffectedItemCount: Int,
            cumulativeFreedBytesEstimate: Int64
        ) {
            self.lastCleanupAt = lastCleanupAt
            self.lastFreedBytesEstimate = lastFreedBytesEstimate
            self.lastAffectedItemCount = lastAffectedItemCount
            self.cumulativeFreedBytesEstimate = cumulativeFreedBytesEstimate
        }
    }

    private static var defaults: UserDefaults { .standard }

    public static func loadSnapshot() -> Snapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    public static func saveSnapshot(_ snapshot: Snapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
    }

    public static func loadCleanupSummary() -> CleanupSummary? {
        guard let data = defaults.data(forKey: cleanupKey) else { return nil }
        return try? JSONDecoder().decode(CleanupSummary.self, from: data)
    }

    /// Добавляет запись о завершённой быстрой очистке (оценка байт и число затронутых позиций).
    public static func recordCleanup(lastFreedBytesEstimate: Int64, affectedItemCount: Int) {
        let now = Date()
        let prev = loadCleanupSummary()
        let cumulative = (prev?.cumulativeFreedBytesEstimate ?? 0) + max(0, lastFreedBytesEstimate)
        let next = CleanupSummary(
            lastCleanupAt: now,
            lastFreedBytesEstimate: max(0, lastFreedBytesEstimate),
            lastAffectedItemCount: max(0, affectedItemCount),
            cumulativeFreedBytesEstimate: cumulative
        )
        if let data = try? JSONEncoder().encode(next) {
            defaults.set(data, forKey: cleanupKey)
        }
        NotificationCenter.default.post(name: .memoryOverviewCleanupRecorded, object: nil)
    }
}

extension Notification.Name {
    public static let memoryOverviewCleanupRecorded = Notification.Name("MacosStorageCleaner.memoryOverviewCleanupRecorded")
}

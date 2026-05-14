import Foundation

/// Свободное и общее место на томе, где лежит указанный путь (без SwiftUI).
public struct VolumeCapacityInfo: Sendable, Equatable {
    public let totalBytes: Int64
    /// Оценка «важного» свободного места (как для установки приложений), см. Apple `volumeAvailableCapacityForImportantUsage`.
    public let availableBytes: Int64

    public init(totalBytes: Int64, availableBytes: Int64) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
    }

    public var usedBytes: Int64 {
        max(0, totalBytes - availableBytes)
    }
}

public enum VolumeCapacityReader: Sendable {
    /// Читает ёмкость тома для URL (обычно домашняя папка пользователя).
    public static func readForVolumeContaining(url: URL) -> VolumeCapacityInfo? {
        let u = url.standardizedFileURL
        guard
            let values = try? u.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey,
            ]),
            let total = values.volumeTotalCapacity
        else { return nil }

        let availableImportant = values.volumeAvailableCapacityForImportantUsage.map { Int64($0) }
        let availableOpportunistic = values.volumeAvailableCapacity.map { Int64($0) }
        let available = availableImportant ?? availableOpportunistic ?? 0
        return VolumeCapacityInfo(totalBytes: Int64(total), availableBytes: max(0, available))
    }
}

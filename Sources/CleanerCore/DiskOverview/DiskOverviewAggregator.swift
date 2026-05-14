import Foundation

/// Верхнеуровневые «ведра» для диаграммы обзора при листинге корня `/`.
public enum DiskOverviewBucket: String, Sendable, CaseIterable, Identifiable {
    case userSpace
    case applications
    case system
    case dataAndVolumes
    case other

    public var id: String { rawValue }
}

/// Агрегат по уже полученному поверхностному списку (без дополнительного обхода).
public struct DiskOverviewSlice: Sendable, Equatable, Identifiable {
    public let bucket: DiskOverviewBucket
    public let itemCount: Int
    public let knownFileBytes: Int64

    public var id: String { bucket.rawValue }

    public init(bucket: DiskOverviewBucket, itemCount: Int, knownFileBytes: Int64) {
        self.bucket = bucket
        self.itemCount = itemCount
        self.knownFileBytes = knownFileBytes
    }
}

public enum DiskOverviewAggregator: Sendable {
    /// Агрегирует дочерние элементы корня `/` по фиксированным правилам из спецификации.
    public static func aggregateSystemRootItems(_ items: [DirectoryListingItem]) -> [DiskOverviewSlice] {
        var counts: [DiskOverviewBucket: Int] = [:]
        var bytes: [DiskOverviewBucket: Int64] = [:]
        for b in DiskOverviewBucket.allCases {
            counts[b] = 0
            bytes[b] = 0
        }

        for item in items {
            let bucket = bucketForRootChild(name: item.name)
            counts[bucket, default: 0] += 1
            if let s = item.sizeBytes {
                bytes[bucket, default: 0] += s
            }
        }

        return DiskOverviewBucket.allCases.map { b in
            DiskOverviewSlice(bucket: b, itemCount: counts[b] ?? 0, knownFileBytes: bytes[b] ?? 0)
        }
    }

    private static func bucketForRootChild(name: String) -> DiskOverviewBucket {
        switch name {
        case "Users":
            return .userSpace
        case "Applications":
            return .applications
        case "System", "usr", "bin", "sbin", "etc", "cores":
            return .system
        case "Library", "private", "var", "Volumes", "opt", "tmp", "dev":
            return .dataAndVolumes
        default:
            return .other
        }
    }
}

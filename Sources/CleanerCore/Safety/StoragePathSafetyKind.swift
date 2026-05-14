import Foundation

/// Эвристическая оценка пути для UI (не гарантия безопасности операций).
public enum StoragePathSafetyKind: String, Sendable, Equatable, CaseIterable {
    case neutral
    case relativelySafeCleanupCandidate
    case important
}

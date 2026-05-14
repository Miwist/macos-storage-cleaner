import Foundation

/// Ход объёмного анализа памяти (для шкалы прогресса в UI).
public struct VolumeStorageScanProgress: Sendable {
    public let completedPhaseIndex: Int
    public let totalPhases: Int
    public let currentCategory: StorageCategory
    public let overallFraction: Double

    public init(completedPhaseIndex: Int, totalPhases: Int, currentCategory: StorageCategory, overallFraction: Double) {
        self.completedPhaseIndex = completedPhaseIndex
        self.totalPhases = totalPhases
        self.currentCategory = currentCategory
        self.overallFraction = min(1, max(0, overallFraction))
    }
}

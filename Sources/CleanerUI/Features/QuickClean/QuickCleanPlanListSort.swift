import CleanerCore
import Foundation

/// Сортировка списка целей плана быстрой очистки (только UI).
enum QuickCleanPlanListSort: String, CaseIterable, Identifiable, Hashable {
    case nameAZ
    case nameZA
    case sizeLargeFirst
    case sizeSmallFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nameAZ: return "По имени (А → Я)"
        case .nameZA: return "По имени (Я → А)"
        case .sizeLargeFirst: return "По размеру (сначала крупные)"
        case .sizeSmallFirst: return "По размеру (сначала мелкие)"
        }
    }

    /// Стабильная сортировка: при равенстве размеров — по имени А→Я.
    func sortingComparator() -> (QuickCleanPlanTarget, QuickCleanPlanTarget) -> Bool {
        switch self {
        case .nameAZ:
            return { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        case .nameZA:
            return { $0.displayName.localizedStandardCompare($1.displayName) == .orderedDescending }
        case .sizeLargeFirst:
            return { Self.compareBySize(lhs: $0, rhs: $1, largeFirst: true) }
        case .sizeSmallFirst:
            return { Self.compareBySize(lhs: $0, rhs: $1, largeFirst: false) }
        }
    }

    private static func compareBySize(lhs: QuickCleanPlanTarget, rhs: QuickCleanPlanTarget, largeFirst: Bool) -> Bool {
        switch (lhs.estimatedBytes, rhs.estimatedBytes) {
        case let (l?, r?):
            if l != r {
                return largeFirst ? (l > r) : (l < r)
            }
            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        case (nil, nil):
            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        }
    }
}

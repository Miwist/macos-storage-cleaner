import CleanerCore
import Foundation

/// Сортировка списка «Крупные файлы и папки» в быстрой очистке.
enum LargeSpaceHintsSortMode: String, CaseIterable, Identifiable, Hashable {
    /// Как при поиске: сначала папки, затем по убыванию размера.
    case foldersThenSizeDesc
    case nameAZ
    case nameZA
    case sizeLargeFirst
    case sizeSmallFirst
    case filesThenFolders
    /// Сначала «часто можно удалить», потом нейтральные, затем «лучше не трогать»; внутри группы — по размеру.
    case safetyCleanupFirst
    /// Сначала «лучше не трогать» — осторожный просмотр.
    case safetyImportantFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .foldersThenSizeDesc: return "Папки сверху, по размеру (как при поиске)"
        case .nameAZ: return "По имени (А → Я)"
        case .nameZA: return "По имени (Я → А)"
        case .sizeLargeFirst: return "По размеру (сначала крупные)"
        case .sizeSmallFirst: return "По размеру (сначала мелкие)"
        case .filesThenFolders: return "Сначала файлы, затем папки"
        case .safetyCleanupFirst: return "По подсказке: сначала удобные для очистки"
        case .safetyImportantFirst: return "По подсказке: сначала важные (осторожно)"
        }
    }

    func sortingComparator() -> (LargeSpaceCandidate, LargeSpaceCandidate) -> Bool {
        switch self {
        case .foldersThenSizeDesc:
            return { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory && !rhs.isDirectory }
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize > rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        case .nameAZ:
            return { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        case .nameZA:
            return { $0.displayName.localizedStandardCompare($1.displayName) == .orderedDescending }
        case .sizeLargeFirst:
            return { lhs, rhs in
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize > rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        case .sizeSmallFirst:
            return { lhs, rhs in
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize < rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        case .filesThenFolders:
            return { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory { return !lhs.isDirectory && rhs.isDirectory }
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize > rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        case .safetyCleanupFirst:
            return { lhs, rhs in
                let la = Self.safetyRankCleanupFirst(lhs.safetyKind)
                let ra = Self.safetyRankCleanupFirst(rhs.safetyKind)
                if la != ra { return la < ra }
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize > rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        case .safetyImportantFirst:
            return { lhs, rhs in
                let la = Self.safetyRankImportantFirst(lhs.safetyKind)
                let ra = Self.safetyRankImportantFirst(rhs.safetyKind)
                if la != ra { return la < ra }
                if lhs.byteSize != rhs.byteSize { return lhs.byteSize > rhs.byteSize }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
        }
    }

    /// Меньше — выше в списке при режиме «удобные для очистки сверху».
    private static func safetyRankCleanupFirst(_ kind: StoragePathSafetyKind) -> Int {
        switch kind {
        case .relativelySafeCleanupCandidate: return 0
        case .neutral: return 1
        case .important: return 2
        }
    }

    /// Меньше — выше при режиме «важные сверху».
    private static func safetyRankImportantFirst(_ kind: StoragePathSafetyKind) -> Int {
        switch kind {
        case .important: return 0
        case .neutral: return 1
        case .relativelySafeCleanupCandidate: return 2
        }
    }
}

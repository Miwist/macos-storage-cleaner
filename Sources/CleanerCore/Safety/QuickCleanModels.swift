import Foundation

/// Категория быстрой очистки (логические корни задаются в планировщике).
public enum QuickCleanCategory: String, Sendable, CaseIterable, Identifiable {
    case userCaches
    case userTemporaryFiles
    case emptyTrashPermanently

    public var id: String { rawValue }
}

/// Один верхнеуровневый объект внутри корня категории (для выборочного выполнения плана).
public struct QuickCleanPlanTarget: Sendable, Identifiable, Equatable {
    public let path: String
    public let displayName: String
    /// Оценка занятого места: для файла — размер файла; для папки — `totalFileAllocatedSize`, если система отдала.
    public let estimatedBytes: Int64?
    public let isDirectory: Bool

    public var id: String { path }

    public init(path: String, displayName: String, estimatedBytes: Int64?, isDirectory: Bool) {
        self.path = path
        self.displayName = displayName
        self.estimatedBytes = estimatedBytes
        self.isDirectory = isDirectory
    }
}

/// Одна строка плана: что будет затронуто и грубая оценка без глубокого обхода.
public struct QuickCleanPlanLine: Sendable, Equatable {
    public let category: QuickCleanCategory
    public let rootPath: String
    public let topLevelEntryCount: Int
    public let knownFileBytes: Int64
    /// Прямые дочерние элементы корня категории; снятие с плана выполняется в UI по `path`.
    public let targets: [QuickCleanPlanTarget]

    public init(
        category: QuickCleanCategory,
        rootPath: String,
        topLevelEntryCount: Int,
        knownFileBytes: Int64,
        targets: [QuickCleanPlanTarget] = []
    ) {
        self.category = category
        self.rootPath = rootPath
        self.topLevelEntryCount = topLevelEntryCount
        self.knownFileBytes = knownFileBytes
        self.targets = targets
    }
}

public struct QuickCleanPlan: Sendable, Equatable {
    public let lines: [QuickCleanPlanLine]

    public init(lines: [QuickCleanPlanLine]) {
        self.lines = lines
    }

    /// Все пути из строк плана (для инициализации «включено всё»).
    public var allTargetPaths: Set<String> {
        Set(lines.flatMap { $0.targets.map(\.path) })
    }
}

/// Какие именно верхнеуровневые объекты обработать. `nil` по категории — эта категория не выполняется.
public struct QuickCleanExecutionSelection: Sendable, Equatable {
    public let caches: Set<String>?
    public let temporaryFiles: Set<String>?
    public let trash: Set<String>?
    public let permanentlyEmptyTrash: Bool

    public init(
        caches: Set<String>?,
        temporaryFiles: Set<String>?,
        trash: Set<String>?,
        permanentlyEmptyTrash: Bool
    ) {
        self.caches = caches
        self.temporaryFiles = temporaryFiles
        self.trash = trash
        self.permanentlyEmptyTrash = permanentlyEmptyTrash
    }
}

public enum QuickCleanEntryOutcome: Sendable, Equatable {
    case movedToTrash
    case permanentlyRemoved
    case skipped(reason: String)
}

public struct QuickCleanEntryResult: Sendable, Equatable {
    public let path: String
    public let outcome: QuickCleanEntryOutcome

    public init(path: String, outcome: QuickCleanEntryOutcome) {
        self.path = path
        self.outcome = outcome
    }
}

public struct QuickCleanRunReport: Sendable, Equatable {
    public let category: QuickCleanCategory
    public let entries: [QuickCleanEntryResult]

    public init(category: QuickCleanCategory, entries: [QuickCleanEntryResult]) {
        self.category = category
        self.entries = entries
    }
}

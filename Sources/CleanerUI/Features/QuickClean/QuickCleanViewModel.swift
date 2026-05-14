import CleanerCore
import Foundation
import Observation

@MainActor
@Observable
final class QuickCleanViewModel {
    private let service = QuickCleanService()

    var selectedCategories: Set<QuickCleanCategory> = [.userCaches, .userTemporaryFiles]
    var acknowledgesIrreversibleTrashPurge = false

    var plan: QuickCleanPlan?
    /// Пути верхнего уровня, которые остаются в плане выполнения (снятая галочка — путь удаляется отсюда).
    var includedTargetPaths: Set<String> = []

    var isPlanning = false
    var isRunning = false
    var reports: [QuickCleanRunReport]?
    var errorMessage: String?

    var largeHints: [LargeSpaceCandidate]?
    var isFindingLargeHints = false

    var hasIncludedWork: Bool {
        guard let plan else { return false }
        let cats = categoriesForPlanAndRun()
        for line in plan.lines where cats.contains(line.category) {
            if line.targets.contains(where: { includedTargetPaths.contains($0.path) }) {
                return true
            }
        }
        return false
    }

    func categoriesForPlanAndRun() -> Set<QuickCleanCategory> {
        var set = selectedCategories
        if set.contains(.emptyTrashPermanently), !acknowledgesIrreversibleTrashPurge {
            set.remove(.emptyTrashPermanently)
        }
        return set
    }

    func preparePlan() async {
        isPlanning = true
        errorMessage = nil
        defer { isPlanning = false }

        let categories = categoriesForPlanAndRun()
        guard !categories.isEmpty else {
            plan = nil
            includedTargetPaths = []
            errorMessage = "Отметьте хотя бы один пункт ниже. Для очистки корзины включите отдельное согласие."
            return
        }

        do {
            let newPlan = try await service.makePlan(categories: categories)
            plan = newPlan
            includedTargetPaths = newPlan.allTargetPaths
        } catch {
            plan = nil
            includedTargetPaths = []
            errorMessage = "Не удалось составить план. Попробуйте ещё раз."
        }
    }

    func includeAllTargets(for category: QuickCleanCategory) {
        guard let plan else { return }
        guard let line = plan.lines.first(where: { $0.category == category }) else { return }
        var next = includedTargetPaths
        for target in line.targets {
            next.insert(target.path)
        }
        includedTargetPaths = next
    }

    func excludeAllTargets(for category: QuickCleanCategory) {
        guard let plan else { return }
        guard let line = plan.lines.first(where: { $0.category == category }) else { return }
        var next = includedTargetPaths
        for target in line.targets {
            next.remove(target.path)
        }
        includedTargetPaths = next
    }

    func runSelected() async {
        guard let plan else {
            errorMessage = "Сначала подготовьте план."
            return
        }
        guard hasIncludedWork else {
            errorMessage = "Отметьте хотя бы один объект в плане или снимите лишние категории сверху."
            return
        }

        let categories = categoriesForPlanAndRun()
        guard !categories.isEmpty else {
            errorMessage = "Сначала выберите действия и подтвердите опасные пункты."
            return
        }

        let selection = buildExecutionSelection(plan: plan, categories: categories)

        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        let reps = await service.execute(selection: selection)
        reports = reps

        let freed = QuickCleanFreedSpaceEstimator.estimatedFreedBytes(plan: plan, reports: reps)
        let n = QuickCleanFreedSpaceEstimator.affectedItemCount(reports: reps)
        if freed > 0 || n > 0 {
            MemoryOverviewPersistence.recordCleanup(lastFreedBytesEstimate: freed, affectedItemCount: n)
        }
    }

    private func buildExecutionSelection(plan: QuickCleanPlan, categories: Set<QuickCleanCategory>) -> QuickCleanExecutionSelection {
        let map = Dictionary(uniqueKeysWithValues: plan.lines.map { ($0.category, $0) })

        func pathSubset(for category: QuickCleanCategory) -> Set<String>? {
            guard categories.contains(category), let line = map[category] else { return nil }
            let subset = Set(line.targets.map(\.path).filter { includedTargetPaths.contains($0) })
            return subset.isEmpty ? nil : subset
        }

        let permanentTrash = categories.contains(.emptyTrashPermanently) && acknowledgesIrreversibleTrashPurge

        return QuickCleanExecutionSelection(
            caches: pathSubset(for: .userCaches),
            temporaryFiles: pathSubset(for: .userTemporaryFiles),
            trash: pathSubset(for: .emptyTrashPermanently),
            permanentlyEmptyTrash: permanentTrash
        )
    }

    func findLargeItems() async {
        isFindingLargeHints = true
        errorMessage = nil
        defer { isFindingLargeHints = false }
        largeHints = await LargeSpaceHintsScanner.findCandidates()
    }

    func resetOutcome() {
        reports = nil
        plan = nil
        includedTargetPaths = []
        largeHints = nil
    }
}

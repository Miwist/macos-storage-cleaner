import Foundation

public enum QuickCleanFreedSpaceEstimator: Sendable {
    /// Суммирует `estimatedBytes` из плана по путям, которые в отчёте ушли в корзину или удалены навсегда.
    public static func estimatedFreedBytes(plan: QuickCleanPlan, reports: [QuickCleanRunReport]) -> Int64 {
        let pathToTarget = Dictionary(
            uniqueKeysWithValues: plan.lines.flatMap(\.targets).map { ($0.path, $0) }
        )
        var sum: Int64 = 0
        for report in reports {
            for entry in report.entries {
                switch entry.outcome {
                case .movedToTrash, .permanentlyRemoved:
                    if let t = pathToTarget[entry.path], let b = t.estimatedBytes {
                        sum += b
                    }
                case .skipped:
                    break
                }
            }
        }
        return sum
    }

    public static func affectedItemCount(reports: [QuickCleanRunReport]) -> Int {
        reports.flatMap(\.entries).filter {
            switch $0.outcome {
            case .movedToTrash, .permanentlyRemoved: return true
            case .skipped: return false
            }
        }.count
    }
}

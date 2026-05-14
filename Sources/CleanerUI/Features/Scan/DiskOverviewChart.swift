import Charts
import CleanerCore
import SwiftUI

/// Столбчатая диаграмма по агрегату дочерних элементов `/` (без дополнительного обхода).
struct DiskOverviewChart: View {
    let slices: [DiskOverviewSlice]

    var body: some View {
        Chart(slices) { slice in
            BarMark(
                x: .value("Элементов", slice.itemCount),
                y: .value("Категория", title(for: slice.bucket))
            )
            .annotation(position: .trailing, alignment: .leading) {
                if slice.itemCount == 0 {
                    Text("0")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("\(slice.itemCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartXAxis(.automatic)
        .chartYAxis(.automatic)
        .frame(height: 220)
    }

    private func title(for bucket: DiskOverviewBucket) -> String {
        switch bucket {
        case .userSpace: "Пользователь"
        case .applications: "Приложения"
        case .system: "Система"
        case .dataAndVolumes: "Данные"
        case .other: "Прочее"
        }
    }
}

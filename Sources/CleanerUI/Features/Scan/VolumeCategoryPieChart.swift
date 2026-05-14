import Charts
import CleanerCore
import SwiftUI

/// Круговая диаграмма по результатам анализа памяти: проценты, подсказка при наведении, выбор раздела.
struct VolumeCategoryPieChart: View {
    let totals: [StorageCategoryTotal]
    /// Подсветка сектора и подсказка (наведение / выбор угла в Charts).
    @Binding var hoveredCategory: StorageCategory?
    let onSelectCategory: (StorageCategory) -> Void

    private struct Slice: Identifiable {
        let id: StorageCategory
        let title: String
        let bytes: Int64
        let color: Color
        let percent: Double
    }

    private var slices: [Slice] {
        let positive = totals.filter { $0.bytes > 0 }
        let sum = positive.reduce(Int64(0)) { $0 + $1.bytes }
        guard sum > 0 else { return [] }
        return positive
            .sorted { $0.bytes > $1.bytes }
            .map { total in
                let pct = 100.0 * Double(total.bytes) / Double(sum)
                return Slice(
                    id: total.category,
                    title: MemoryPresentation.title(for: total.category),
                    bytes: total.bytes,
                    color: MemoryPresentation.tint(for: total.category),
                    percent: pct
                )
            }
    }

    private var totalBytes: Int64 {
        slices.reduce(0) { $0 + $1.bytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if slices.isEmpty {
                Text("Нет ненулевых категорий для диаграммы.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ZStack(alignment: .topLeading) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Размер", slice.bytes),
                            innerRadius: .ratio(0.52),
                            angularInset: 1.2
                        )
                        .foregroundStyle(by: .value("Категория", slice.id))
                        .opacity(hoveredCategory == slice.id ? 1 : 0.9)
                        .annotation(position: .overlay, alignment: .center) {
                            if slice.percent >= 5.5 {
                                Text(String(format: "%.0f%%", slice.percent))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartForegroundStyleScale(
                        domain: slices.map(\.id),
                        range: slices.map(\.color)
                    )
                    .frame(height: 220)
                    .chartOverlay { _ in
                        GeometryReader { geo in
                            Color.clear
                                .contentShape(Rectangle())
                                .onContinuousHover { phase in
                                    switch phase {
                                    case .active(let location):
                                        hoveredCategory = category(at: location, in: geo.size)
                                    case .ended:
                                        hoveredCategory = nil
                                    }
                                }
                                .simultaneousGesture(
                                    SpatialTapGesture(coordinateSpace: .local)
                                        .onEnded { event in
                                            if let cat = category(at: event.location, in: geo.size) {
                                                onSelectCategory(cat)
                                            }
                                        }
                                )
                        }
                    }

                    if let cat = hoveredCategory, let slice = slices.first(where: { $0.id == cat }) {
                        tooltip(for: slice)
                            .padding(.top, 6)
                            .padding(.leading, 6)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }

                legendGrid
            }
        }
    }

    private func tooltip(for slice: Slice) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(slice.title)
                .font(.caption.weight(.semibold))
            Text("\(String(format: "%.1f", slice.percent))% · \(ByteSizeFormatting.string(forByteCount: slice.bytes))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var legendGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(slices) { slice in
                Button {
                    onSelectCategory(slice.id)
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(slice.color.gradient)
                            .frame(width: 10, height: 10)
                        Text(slice.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(String(format: "%.0f%%", slice.percent))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(hoveredCategory == slice.id ? Color.primary.opacity(0.06) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .onHover { inside in
                    if inside { hoveredCategory = slice.id }
                }
            }
        }
    }

    /// Преобразует точку в категорию по тому же порядку и долям, что и `SectorMark`.
    private func category(at location: CGPoint, in size: CGSize) -> StorageCategory? {
        guard totalBytes > 0, !slices.isEmpty else { return nil }
        guard size.width > 8, size.height > 8 else { return nil }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = hypot(dx, dy)
        let maxR = min(size.width, size.height) / 2
        let outerR = maxR * 0.92
        let innerR = outerR * 0.52
        guard distance >= innerR * 0.98, distance <= outerR * 1.02 else { return nil }

        var angle = atan2(dy, dx)
        angle += .pi / 2
        if angle < 0 { angle += 2 * .pi }
        if angle >= 2 * .pi { angle -= 2 * .pi }

        let total = Double(totalBytes)
        var sweepStart: Double = 0
        for slice in slices {
            let span = 2 * .pi * (Double(slice.bytes) / total)
            if angle >= sweepStart && angle < sweepStart + span {
                return slice.id
            }
            sweepStart += span
        }
        return slices.last?.id
    }
}

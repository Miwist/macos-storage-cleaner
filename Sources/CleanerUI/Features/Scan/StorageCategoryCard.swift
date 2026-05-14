import CleanerCore
import SwiftUI

struct StorageCategoryCard: View {
    let total: StorageCategoryTotal
    let showTechnicalPath: Bool

    var body: some View {
        let tint = MemoryPresentation.tint(for: total.category)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: MemoryPresentation.symbol(for: total.category))
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(MemoryPresentation.title(for: total.category))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(total.bytes > 0 ? ByteSizeFormatting.string(forByteCount: total.bytes) : "нет данных")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(tint)
                }
                Spacer(minLength: 0)
            }

            if showTechnicalPath {
                Text(total.category.typicalRootURL().path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Text("Нажмите, чтобы посмотреть содержимое")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: tint.opacity(0.25), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }
}

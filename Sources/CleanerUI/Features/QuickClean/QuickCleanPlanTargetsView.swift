import CleanerCore
import SwiftUI

/// Список целей плана: папки сверху, отдельные файлы ниже; длинный список файлов сворачивается; сортировка настраивается.
struct QuickCleanPlanTargetsView: View {
    let line: QuickCleanPlanLine
    @Binding var includedPaths: Set<String>
    @Binding var looseFilesExpanded: Bool

    @State private var foldersSort: QuickCleanPlanListSort = .nameAZ
    @State private var filesSort: QuickCleanPlanListSort = .nameAZ

    private let maxCollapsedLooseFiles = 8

    /// Ширина колонки чекбокса в `Form`, чтобы заголовки секций совпадали с текстом строк.
    private var checkboxColumnWidth: CGFloat { 22 }
    private var iconColumnWidth: CGFloat { 20 }
    private var sizeColumnMinWidth: CGFloat { 80 }

    private var folders: [QuickCleanPlanTarget] {
        line.targets.filter(\.isDirectory)
    }

    private var looseFiles: [QuickCleanPlanTarget] {
        line.targets.filter { !$0.isDirectory }
    }

    private var sortedFolders: [QuickCleanPlanTarget] {
        folders.sorted(by: foldersSort.sortingComparator())
    }

    private var sortedLooseFiles: [QuickCleanPlanTarget] {
        looseFiles.sorted(by: filesSort.sortingComparator())
    }

    private var visibleLooseFiles: [QuickCleanPlanTarget] {
        if looseFilesExpanded || sortedLooseFiles.count <= maxCollapsedLooseFiles {
            return sortedLooseFiles
        }
        return Array(sortedLooseFiles.prefix(maxCollapsedLooseFiles))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !folders.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeaderWithSort(title: "Папки", systemImage: "folder.fill", sort: $foldersSort)
                    ForEach(sortedFolders) { target in
                        targetRow(target, icon: "folder.fill")
                    }
                }
            }

            if !looseFiles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeaderWithSort(title: "Отдельные файлы", systemImage: "doc.fill", sort: $filesSort)

                    ForEach(visibleLooseFiles) { target in
                        targetRow(target, icon: "doc.fill")
                    }

                    if !looseFilesExpanded, sortedLooseFiles.count > maxCollapsedLooseFiles {
                        HStack(spacing: 10) {
                            Color.clear
                                .frame(width: checkboxColumnWidth)
                                .accessibilityHidden(true)
                            Color.clear
                                .frame(width: iconColumnWidth)
                                .accessibilityHidden(true)
                            Button("Показать ещё файлы (\(sortedLooseFiles.count - maxCollapsedLooseFiles))") {
                                looseFilesExpanded = true
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            Spacer(minLength: 0)
                        }
                    } else if looseFilesExpanded, sortedLooseFiles.count > maxCollapsedLooseFiles {
                        HStack(spacing: 10) {
                            Color.clear
                                .frame(width: checkboxColumnWidth)
                                .accessibilityHidden(true)
                            Color.clear
                                .frame(width: iconColumnWidth)
                                .accessibilityHidden(true)
                            Button("Свернуть список файлов") {
                                looseFilesExpanded = false
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func sectionHeaderWithSort(title: String, systemImage: String, sort: Binding<QuickCleanPlanListSort>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Color.clear
                .frame(width: checkboxColumnWidth)
                .accessibilityHidden(true)
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: iconColumnWidth, height: 20, alignment: .center)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Menu {
                ForEach(QuickCleanPlanListSort.allCases) { mode in
                    Button {
                        sort.wrappedValue = mode
                    } label: {
                        HStack {
                            Text(mode.title)
                            if sort.wrappedValue == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Сортировка списка")
        }
    }

    private func targetRow(_ target: QuickCleanPlanTarget, icon: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle("", isOn: inclusionBinding(for: target.path))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .fixedSize()

            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: iconColumnWidth, height: 20, alignment: .center)
                .imageScale(.small)

            Text(target.displayName)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(sizeLabel(for: target))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .frame(minWidth: sizeColumnMinWidth, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func sizeLabel(for target: QuickCleanPlanTarget) -> String {
        ByteSizeFormatting.string(forOptionalByteCount: target.estimatedBytes, missing: target.isDirectory ? "оценка…" : "—")
    }

    private func inclusionBinding(for path: String) -> Binding<Bool> {
        Binding(
            get: { includedPaths.contains(path) },
            set: { isOn in
                var next = includedPaths
                if isOn {
                    next.insert(path)
                } else {
                    next.remove(path)
                }
                includedPaths = next
            }
        )
    }
}

import AppKit
import CleanerCore
import SwiftUI

struct QuickCleanView: View {
    @State private var viewModel = QuickCleanViewModel()
    @State private var showRunConfirmation = false
    /// Развёрнут ли длинный список отдельных файлов в плане по категории.
    @State private var looseFileListExpanded: [String: Bool] = [:]
    @State private var largeHintsSort: LargeSpaceHintsSortMode = .foldersThenSizeDesc

    var body: some View {
        Form {
            introSection
            largeHintsSection
            actionsSection
            planSection
            errorSection
            resultsSection
        }
        .formStyle(.grouped)
        .navigationTitle("Быстрая очистка")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("План", systemImage: "doc.text.magnifyingglass") {
                    Task { await viewModel.preparePlan() }
                }
                .disabled(viewModel.isPlanning || viewModel.isRunning)
                .help("Составить список того, что можно сделать")

                Button("Выполнить", systemImage: "play.fill") {
                    showRunConfirmation = true
                }
                .disabled(viewModel.isPlanning || viewModel.isRunning || viewModel.plan == nil || !viewModel.hasIncludedWork)
                .help("Запустить отмеченные действия")

                Button("Сбросить", systemImage: "arrow.counterclockwise") {
                    viewModel.resetOutcome()
                    looseFileListExpanded = [:]
                    largeHintsSort = .foldersThenSizeDesc
                }
                .disabled(viewModel.isRunning)
                .help("Очистить план и результат")
            }
        }
        .confirmationDialog(
            "Запустить выбранные действия?",
            isPresented: $showRunConfirmation,
            titleVisibility: .visible
        ) {
            Button("Запустить") {
                Task { await viewModel.runSelected() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(dialogMessage)
        }
    }

    private var introSection: some View {
        Section {
            Text(
                "Кэши и временные файлы отправляются в корзину. Очистка корзины удаляет выбранные элементы навсегда — только после вашего согласия."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private var largeHintsSection: some View {
        Section {
            Text(
                "Крупные объекты (от примерно 80 МБ) в загрузках, на рабочем столе, в «Видео» и в кэшах. Подсказка, не полный обход диска."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Button("Найти крупные объекты") {
                Task { await viewModel.findLargeItems() }
            }
            .disabled(viewModel.isFindingLargeHints || viewModel.isRunning)

            if viewModel.isFindingLargeHints {
                ProgressView("Ищем…")
            } else if let hints = viewModel.largeHints {
                if hints.isEmpty {
                    Text("Пока ничего крупного не нашли — это хороший знак.")
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        Text("Найдено: \(hints.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Menu {
                            ForEach(LargeSpaceHintsSortMode.allCases) { mode in
                                Button {
                                    largeHintsSort = mode
                                } label: {
                                    HStack {
                                        Text(mode.title)
                                        if largeHintsSort == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .help("Сортировка списка")
                    }
                    .padding(.vertical, 2)

                    ForEach(sortedLargeHints(hints)) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, height: 22, alignment: .center)
                                    .imageScale(.medium)
                                Text(item.displayName)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(ByteSizeFormatting.string(forByteCount: item.byteSize))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                                    .frame(minWidth: 88, alignment: .trailing)
                            }
                            Text(MemoryPresentation.hint(for: item.safetyKind))
                                .font(.caption)
                                .foregroundStyle(MemoryPresentation.hintColor(for: item.safetyKind))
                            Button("Показать в Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        } header: {
            Text("Крупные файлы и папки")
        }
    }

    private var actionsSection: some View {
        Section {
            Toggle("Очистить кэши программ", isOn: binding(for: .userCaches))
            Toggle("Убрать временные файлы этой программы", isOn: binding(for: .userTemporaryFiles))
            Toggle("Навсегда очистить выбранное из корзины", isOn: binding(for: .emptyTrashPermanently))

            if viewModel.selectedCategories.contains(.emptyTrashPermanently) {
                Toggle("Подтверждаю безвозвратное удаление из корзины", isOn: $viewModel.acknowledgesIrreversibleTrashPurge)
                Text(
                    "Выбранные элементы корзины будут удалены без возможности вернуть их здесь. Восстановление возможно только средствами macOS, если система это поддерживает."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("Что включить")
        } footer: {
            Text("Сначала отметьте категории, затем нажмите «План» на панели выше.")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }

    private var includedTargetPathsBinding: Binding<Set<String>> {
        Binding(
            get: { viewModel.includedTargetPaths },
            set: { viewModel.includedTargetPaths = $0 }
        )
    }

    private var planSection: some View {
        Section {
            Text("Снимите галочки с того, что не трогать — на диске ничего не меняется, пока вы не нажмёте «Выполнить».")
                .font(.callout)
                .foregroundStyle(.secondary)

            if viewModel.isPlanning {
                LabeledContent("Составляем список…") {
                    ProgressView()
                        .controlSize(.small)
                }
            } else if let plan = viewModel.plan {
                if plan.lines.isEmpty {
                    ContentUnavailableView(
                        "План пуст",
                        systemImage: "tray",
                        description: Text("Отметьте категории выше и снова нажмите «План».")
                    )
                } else {
                    ForEach(plan.lines, id: \.category) { line in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(title(for: line.category))
                                    .font(.title3.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Menu {
                                    Button("Включить всё в группе") {
                                        viewModel.includeAllTargets(for: line.category)
                                    }
                                    Button("Снять всё в группе") {
                                        viewModel.excludeAllTargets(for: line.category)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .help("Действия для всей группы")
                            }

                            Text(summaryLine(for: line))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if line.targets.isEmpty {
                                Text("На верхнем уровне ничего нет.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                QuickCleanPlanTargetsView(
                                    line: line,
                                    includedPaths: includedTargetPathsBinding,
                                    looseFilesExpanded: looseFilesExpandedBinding(for: line.category)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                ContentUnavailableView(
                    "План не готов",
                    systemImage: "doc.text",
                    description: Text("Нажмите «План» на панели инструментов.")
                )
            }

            if viewModel.isRunning {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Выполняем…")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("План по шагам")
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Section {
                Text(error)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if let reports = viewModel.reports {
            Section("Результат") {
                ForEach(reports, id: \.category) { report in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title(for: report.category))
                            .font(.headline)
                        let moved = report.entries.filter { $0.outcome == .movedToTrash }.count
                        let removed = report.entries.filter { $0.outcome == .permanentlyRemoved }.count
                        let skipped = report.entries.filter {
                            if case .skipped = $0.outcome { return true }
                            return false
                        }
                        Text("В корзину: \(moved). Удалено навсегда: \(removed). Пропущено: \(skipped.count).")
                            .font(.callout)
                        if !skipped.isEmpty {
                            Text("Часть пунктов система не дала обработать — это нормально.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func sortedLargeHints(_ hints: [LargeSpaceCandidate]) -> [LargeSpaceCandidate] {
        hints.sorted(by: largeHintsSort.sortingComparator())
    }

    private func summaryLine(for line: QuickCleanPlanLine) -> String {
        let items = "элементов: \(line.topLevelEntryCount)"
        let filesOnLevel = "файлы на верхнем уровне: \(ByteSizeFormatting.string(forByteCount: line.knownFileBytes))"
        return "\(items), \(filesOnLevel)"
    }

    private func looseFilesExpandedBinding(for category: QuickCleanCategory) -> Binding<Bool> {
        let key = category.rawValue
        return Binding(
            get: { looseFileListExpanded[key, default: false] },
            set: { newValue in
                var next = looseFileListExpanded
                next[key] = newValue
                looseFileListExpanded = next
            }
        )
    }

    private var dialogMessage: String {
        let n = viewModel.includedTargetPaths.count
        let suffix = n > 0 ? " Отмечено позиций: \(n)." : ""
        let cats = viewModel.categoriesForPlanAndRun()
        if cats.isEmpty { return "Отметьте хотя бы одну категорию." }
        var parts: [String] = []
        if cats.contains(.userCaches) { parts.append("кэши → корзина") }
        if cats.contains(.userTemporaryFiles) { parts.append("временные файлы → корзина") }
        if cats.contains(.emptyTrashPermanently), viewModel.acknowledgesIrreversibleTrashPurge {
            parts.append("корзина — безвозвратно")
        }
        return parts.joined(separator: ", ") + suffix
    }

    private func binding(for category: QuickCleanCategory) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    viewModel.selectedCategories.insert(category)
                } else {
                    viewModel.selectedCategories.remove(category)
                }
            }
        )
    }

    private func title(for category: QuickCleanCategory) -> String {
        switch category {
        case .userCaches: "Кэши программ"
        case .userTemporaryFiles: "Временные файлы"
        case .emptyTrashPermanently: "Корзина"
        }
    }
}

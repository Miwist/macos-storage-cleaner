import AppKit
import Charts
import CleanerCore
import Combine
import SwiftUI

struct ScanView: View {
    @State private var model = ScanFolderViewModel()
    @State private var selectedItemIDs = Set<String>()
    @AppStorage("showPathSafetyHighlights") private var showPathSafetyHighlights = true
    @AppStorage("autoAnalyzeStorageOnOpen") private var autoAnalyzeStorageOnOpen = true
    @AppStorage("showTechnicalPaths") private var showTechnicalPaths = false
    @AppStorage("colorfulInterface") private var colorfulInterface = true
    @AppStorage("confirmBeforeMoveToTrash") private var confirmBeforeMoveToTrash = true

    @State private var hoveredVolumeCategory: StorageCategory?
    @State private var itemPendingTrash: DirectoryListingItem?
    @State private var currentFolderTrashPromptPath: String?
    @State private var trashErrorMessage: String?

    private var diskChartSlices: [DiskOverviewSlice] {
        guard model.selectedFolderURL?.path == "/", !model.items.isEmpty else { return [] }
        return DiskOverviewAggregator.aggregateSystemRootItems(model.items)
    }

    private var diskChartTotalItems: Int {
        diskChartSlices.reduce(0) { $0 + $1.itemCount }
    }

    /// Карточки разделов: выбранный на диаграмме или в списке — первым.
    private var displayCategoryTotals: [StorageCategoryTotal] {
        let base = model.volumeCategoryTotals
        guard let pin = model.pinnedStorageCategory,
              let head = base.first(where: { $0.category == pin })
        else { return base }
        return [head] + base.filter { $0.category != pin }
    }

    var body: some View {
        Group {
            if model.isShowingFolderBrowser {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            hero
                            memoryOverviewStrip
                            analysisSection
                        }
                    }
                    .frame(maxHeight: 480)
                    .scrollBounceBehavior(.basedOnSize)

                    folderBrowserChrome
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        hero
                        memoryOverviewStrip
                        analysisSection
                        overviewChrome
                    }
                }
            }
        }
        .background {
            if colorfulInterface {
                backgroundGradient
            }
        }
        .navigationTitle("Память")
        .task {
            await model.bootstrapMemoryOverview(autoRescanCategories: autoAnalyzeStorageOnOpen)
        }
        .onAppear {
            model.refreshVolumeCapacity()
            model.reloadCleanupSummaryFromPersistence()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryOverviewCleanupRecorded)) { _ in
            model.reloadCleanupSummaryFromPersistence()
            model.refreshVolumeCapacity()
        }
        .alert(
            "Переместить в корзину?",
            isPresented: Binding(
                get: { itemPendingTrash != nil },
                set: { if !$0 { itemPendingTrash = nil } }
            ),
            presenting: itemPendingTrash
        ) { entry in
            Button("Отмена", role: .cancel) {
                itemPendingTrash = nil
            }
            Button("Переместить", role: .destructive) {
                let pathItem = entry
                itemPendingTrash = nil
                Task {
                    if let err = await model.moveItemToTrash(pathItem) {
                        trashErrorMessage = err
                    }
                }
            }
        } message: { entry in
            Text("«\(entry.name)» будет отправлен в корзину. При необходимости восстановите объект из корзины Finder, пока вы её не очистите.")
        }
        .alert(
            "Переместить текущую папку в корзину?",
            isPresented: Binding(
                get: { currentFolderTrashPromptPath != nil },
                set: { if !$0 { currentFolderTrashPromptPath = nil } }
            )
        ) {
            Button("Отмена", role: .cancel) {
                currentFolderTrashPromptPath = nil
            }
            Button("Переместить", role: .destructive) {
                currentFolderTrashPromptPath = nil
                Task {
                    if let err = await model.moveCurrentFolderToTrash() {
                        trashErrorMessage = err
                    }
                }
            }
        } message: {
            Text(
                currentFolderTrashPromptPath.map { path in
                    let name = URL(fileURLWithPath: path).lastPathComponent
                    return "Папка «\(name)» будет перемещена в корзину. Просмотр вернётся на уровень выше или к обзору «Память»."
                } ?? ""
            )
        }
        .alert(
            "Не удалось отправить в корзину",
            isPresented: Binding(
                get: { trashErrorMessage != nil },
                set: { if !$0 { trashErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { trashErrorMessage = nil }
        } message: {
            Text(trashErrorMessage ?? "")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.12),
                Color.purple.opacity(0.08),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Что занимает место")
                .font(.largeTitle.weight(.bold))
            Text("Мы оцениваем основные разделы диска — как в настройках Mac, но с возможностью заглянуть глубже.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var memoryOverviewStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let cap = model.volumeCapacity {
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    capacityColumn(title: "Занято", value: cap.usedBytes, symbol: "internaldrive.fill")
                    capacityColumn(title: "Свободно", value: cap.availableBytes, symbol: "arrow.down.circle")
                    capacityColumn(title: "Всего", value: cap.totalBytes, symbol: "cylinder.split.1x2")
                    Spacer(minLength: 0)
                }
                Text("Свободное место — по данным macOS (в т.ч. «важное» для приложений и обновлений).")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Не удалось прочитать ёмкость диска для домашней папки.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let at = model.lastCategorySnapshotAt {
                Text("Снимок оценки по разделам: \(localizedMediumDateTime(at)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let s = model.cleanupSummary {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        "Последняя быстрая очистка (~\(ByteSizeFormatting.string(forByteCount: s.lastFreedBytesEstimate)), \(s.lastAffectedItemCount) объектов): \(localizedMediumDateTime(s.lastCleanupAt))."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    if s.cumulativeFreedBytesEstimate > 0 {
                        Text("За всё время в приложении — оценка ~\(ByteSizeFormatting.string(forByteCount: s.cumulativeFreedBytesEstimate)).")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func capacityColumn(title: String, value: Int64, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(ByteSizeFormatting.string(forByteCount: value))
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
    }

    private func localizedMediumDateTime(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day().month(.abbreviated).year()
                .hour().minute()
                .locale(Locale(identifier: "ru_RU"))
        )
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.isVolumeAnalyzing {
                VStack(alignment: .leading, spacing: 8) {
                    if let phase = model.volumeAnalysisPhase {
                        Text("Сейчас: \(MemoryPresentation.title(for: phase))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Готовим оценку…")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: model.volumeAnalysisProgress)
                        .tint(.accentColor)
                        .animation(.easeInOut(duration: 0.2), value: model.volumeAnalysisProgress)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
                .padding(.horizontal, 16)
            }

            if let err = model.volumeAnalysisError {
                Text(err)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
                    .padding(.horizontal, 16)
            }

            if !model.volumeCategoryTotals.isEmpty, !model.isVolumeAnalyzing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Распределение по разделам")
                        .font(.headline)
                    VolumeCategoryPieChart(
                        totals: model.volumeCategoryTotals,
                        hoveredCategory: $hoveredVolumeCategory,
                        onSelectCategory: { category in
                            selectedItemIDs = []
                            model.openStorageCategory(category)
                        }
                    )
                    Text("Наведите курсор на кольцо — подсказка; щёлкните по сектору или строке списка ниже — откроем папку и закрепим раздел сверху.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
                .padding(.horizontal, 16)
            }
        }
    }

    private var overviewChrome: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button("Обновить оценку") {
                    Task { await model.runVolumeAnalysis() }
                }
                .disabled(model.isVolumeAnalyzing)

                Button("Выбрать папку…") {
                    selectedItemIDs = []
                    model.pickFolder()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Показать всё устройство") {
                    selectedItemIDs = []
                    model.startFullDiskScan()
                }
                .disabled(model.isVolumeAnalyzing)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)

            if !model.volumeCategoryTotals.isEmpty, !model.isVolumeAnalyzing {
                Text("Разделы")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 14)], spacing: 14) {
                    ForEach(displayCategoryTotals) { total in
                        Button {
                            selectedItemIDs = []
                            model.openStorageCategory(total.category)
                        } label: {
                            StorageCategoryCard(total: total, showTechnicalPath: showTechnicalPaths)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            } else if !model.isVolumeAnalyzing, model.volumeCategoryTotals.isEmpty, model.volumeAnalysisError == nil {
                ContentUnavailableView(
                    "Пока нет данных",
                    systemImage: "internaldrive",
                    description: Text("Нажмите «Обновить оценку», чтобы мы подсчитали основные папки.")
                )
                .padding(.vertical, 24)
            }
        }
        .padding(.bottom, 24)
    }

    private var folderBrowserChrome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Button("К обзору памяти") {
                    selectedItemIDs = []
                    model.returnToMemoryOverview()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button {
                    model.goBack()
                    selectedItemIDs = []
                } label: {
                    Label("Назад", systemImage: "chevron.backward")
                }
                .disabled(!model.canGoBack || model.isLoading)

                Button("Открыть") {
                    openSelectedFolder()
                }
                .disabled(!canOpenSelection || model.isLoading)
                .keyboardShortcut(.return, modifiers: [.command])

                Button {
                    Task { await model.reloadListing() }
                } label: {
                    Label("Обновить", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading)

                if model.isLoading {
                    sparkline
                    ProgressView()
                        .controlSize(.small)
                    Text("Загружаем…")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Spacer(minLength: 0)
            }
            .padding(12)

            if model.isFullDiskSession {
                Text("Здесь показаны системные папки верхнего уровня. Если что-то не открывается, в настройках Mac может понадобиться разрешение «Полный доступ к диску».")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }

            if let current = model.selectedFolderURL {
                VStack(alignment: .leading, spacing: 8) {
                    if showTechnicalPaths {
                        Text(current.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    } else {
                        Text(friendlyLocationTitle(for: current))
                            .font(.callout.weight(.medium))
                    }

                    HStack(spacing: 10) {
                        Button("Показать в Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([current])
                        }
                        .buttonStyle(.bordered)

                        if model.canMoveCurrentFolderToTrash() {
                            Button("Переместить в корзину", role: .destructive) {
                                requestMoveCurrentFolderToTrash(current: current)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            chartStrip
            Divider()
            if let message = model.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                Divider()
            }
            disclaimer
            Divider()
            browserContent
        }
    }

    private func friendlyLocationTitle(for url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path == "/" { return "Всё устройство" }
        if path == home { return "Ваша личная папка" }
        if path.hasPrefix(home + "/Downloads") { return "Загрузки" }
        if path.hasPrefix(home + "/Documents") { return "Документы" }
        if path.hasPrefix(home + "/Desktop") { return "Рабочий стол" }
        if path.hasPrefix(home + "/Movies") { return "Видео" }
        if path.hasPrefix(home + "/Pictures") { return "Фото" }
        if path.hasPrefix(home + "/Music") { return "Музыка" }
        if path.hasPrefix(home + "/Library/Caches") { return "Кэши программ" }
        if path.hasPrefix(home + "/.Trash") { return "Корзина" }
        if path == "/Applications" { return "Программы" }
        return url.lastPathComponent.isEmpty ? "Папка" : url.lastPathComponent
    }

    private var disclaimer: some View {
        Text(
            "Подсказки «часто можно удалить» и «лучше не трогать» — это оценка, а не гарантия. Очистка выполняется только вами в разделе «Быстрая очистка»."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var chartStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сводка по системным папкам")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.top, 8)

            if model.selectedFolderURL?.path == "/" {
                if model.isLoading && model.items.isEmpty {
                    ContentUnavailableView(
                        "Считаем…",
                        systemImage: "chart.bar",
                        description: Text("Собираем список верхнего уровня диска.")
                    )
                    .frame(height: 160)
                } else if model.items.isEmpty {
                    Text("Диаграмма появится, когда список папок будет доступен.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                } else if diskChartTotalItems == 0 {
                    Text("Пока нечего показать на диаграмме.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                } else {
                    DiskOverviewChart(slices: diskChartSlices)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            } else {
                Text("Эта диаграмма относится к режиму «Показать всё устройство».")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }

    private var sparkline: some View {
        Chart {
            ForEach(Array(model.loadProgressSamples.indices), id: \.self) { index in
                let value = model.loadProgressSamples[index]
                LineMark(
                    x: .value("Шаг", index),
                    y: .value("Прогресс", value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.secondary)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...1)
        .frame(width: 88, height: 24)
        .accessibilityLabel("Прогресс загрузки")
    }

    private var canOpenSelection: Bool {
        guard selectedItemIDs.count == 1,
              let id = selectedItemIDs.first,
              let item = model.items.first(where: { $0.id == id })
        else { return false }
        return item.isDirectory
    }

    private func openItemIfDirectory(_ item: DirectoryListingItem) {
        guard item.isDirectory else { return }
        selectedItemIDs = []
        model.openDirectory(item)
    }

    @ViewBuilder
    private func rowContextMenu(for item: DirectoryListingItem) -> some View {
        Group {
            Button("Показать в Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.fileURL])
            }
            if model.canMoveItemToTrash(item) {
                Divider()
                Button("Переместить в корзину", role: .destructive) {
                    requestMoveToTrash(item)
                }
            }
        }
    }

    private func rowDoubleClickOpenFolder(for item: DirectoryListingItem) -> some Gesture {
        TapGesture(count: 2).onEnded { _ in
            openItemIfDirectory(item)
        }
    }

    private func requestMoveToTrash(_ item: DirectoryListingItem) {
        guard model.canMoveItemToTrash(item) else { return }
        if confirmBeforeMoveToTrash {
            itemPendingTrash = item
        } else {
            Task {
                if let err = await model.moveItemToTrash(item) {
                    trashErrorMessage = err
                }
            }
        }
    }

    private func requestMoveCurrentFolderToTrash(current: URL) {
        guard model.canMoveCurrentFolderToTrash() else { return }
        if confirmBeforeMoveToTrash {
            currentFolderTrashPromptPath = current.path
        } else {
            Task {
                if let err = await model.moveCurrentFolderToTrash() {
                    trashErrorMessage = err
                }
            }
        }
    }

    private func openSelectedFolder() {
        guard let id = selectedItemIDs.first,
              let item = model.items.first(where: { $0.id == id }),
              item.isDirectory
        else { return }
        selectedItemIDs = []
        model.openDirectory(item)
    }

    @ViewBuilder
    private var browserContent: some View {
        if model.isLoading && model.items.isEmpty {
            ProgressView("Открываем папку…")
                .frame(maxWidth: .infinity, minHeight: 220)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage != nil {
            ContentUnavailableView(
                "Не удалось открыть",
                systemImage: "exclamationmark.triangle",
                description: Text("Проверьте сообщение выше. Иногда macOS ограничивает доступ к системным областям.")
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage == nil {
            ContentUnavailableView(
                "Пусто",
                systemImage: "doc",
                description: Text("Здесь пока ничего нет.")
            )
            .frame(maxWidth: .infinity, minHeight: 220)
        } else {
            Table(model.items, selection: $selectedItemIDs) {
                TableColumn("Имя") { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc")
                            .foregroundStyle(.secondary)
                        Text(item.name)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .highPriorityGesture(rowDoubleClickOpenFolder(for: item))
                    .contextMenu {
                        rowContextMenu(for: item)
                    }
                    .help(item.isDirectory ? "Двойной щелчок — открыть папку" : "")
                }
                .width(min: 180, ideal: 280)
                TableColumn("Подсказка") { item in
                    Group {
                        if showPathSafetyHighlights {
                            Text(MemoryPresentation.hint(for: item.safetyKind))
                                .font(.caption)
                                .foregroundStyle(MemoryPresentation.hintColor(for: item.safetyKind))
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .highPriorityGesture(rowDoubleClickOpenFolder(for: item))
                    .contextMenu {
                        rowContextMenu(for: item)
                    }
                }
                .width(min: 120, ideal: 160)
                TableColumn("Размер") { item in
                    Text(item.sizeDisplayString())
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .contentShape(Rectangle())
                        .highPriorityGesture(rowDoubleClickOpenFolder(for: item))
                        .contextMenu {
                            rowContextMenu(for: item)
                        }
                }
                .width(min: 72, ideal: 100)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 320)

            Text("Для папок: сначала размер из метаданных APFS (totalFileAllocatedSize), при отсутствии — приблизительная сумма прямых вложений (до 500 элементов). Иначе — «оценка недоступна».")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.top, 6)
        }
    }
}

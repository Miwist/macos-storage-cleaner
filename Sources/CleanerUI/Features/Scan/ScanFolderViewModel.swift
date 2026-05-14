import CleanerCore
import Foundation
import Observation

@MainActor
@Observable
final class ScanFolderViewModel {
    private let listing: ShallowDirectoryListingService
    private let volumeScanner = VolumeStorageScanner()

    /// Пустой стек означает экран обзора памяти; непустой — просмотр конкретной папки.
    private var pathStack: [URL] = []

    private var progressTicker: Task<Void, Never>?
    private var loadProgressStarted: Date?

    var selectedFolderURL: URL? { pathStack.last }

    var rootFolderURL: URL? { pathStack.first }

    var items: [DirectoryListingItem] = []
    var isLoading = false
    var errorMessage: String?

    var loadProgressSamples: [Double] = []

    // MARK: - Обзор памяти (как «Хранилище»)

    var volumeCategoryTotals: [StorageCategoryTotal] = []
    var isVolumeAnalyzing = false
    var volumeAnalysisProgress: Double = 0
    var volumeAnalysisPhase: StorageCategory?
    var volumeAnalysisError: String?

    /// После выбора из диаграммы или карточки — этот раздел показывается первым в сетке.
    var pinnedStorageCategory: StorageCategory?

    /// Ёмкость тома с домашней папкой (занято / свободно / всего).
    var volumeCapacity: VolumeCapacityInfo?

    /// Когда последний раз сохранили снимок оценки по категориям (после успешного анализа).
    var lastCategorySnapshotAt: Date?

    /// Последняя и накопительная оценка освобождения места через быструю очистку.
    var cleanupSummary: MemoryOverviewPersistence.CleanupSummary?

    init(listing: ShallowDirectoryListingService = ShallowDirectoryListingService()) {
        self.listing = listing
        bootstrapFromPersistence()
    }

    /// Загрузка сохранённого снимка категорий и истории очистки.
    func bootstrapFromPersistence() {
        if let snap = MemoryOverviewPersistence.loadSnapshot() {
            volumeCategoryTotals = snap.categoryTotals.sorted { $0.bytes > $1.bytes }
            lastCategorySnapshotAt = snap.scannedAt
        }
        cleanupSummary = MemoryOverviewPersistence.loadCleanupSummary()
    }

    func reloadCleanupSummaryFromPersistence() {
        cleanupSummary = MemoryOverviewPersistence.loadCleanupSummary()
    }

    /// Обновляет цифры тома (быстро, без обхода каталогов).
    func refreshVolumeCapacity() {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        volumeCapacity = VolumeCapacityReader.readForVolumeContaining(url: home)
    }

    /// При первом появлении «Память»: подтянуть диск, при необходимости заново оценить категории.
    func bootstrapMemoryOverview(autoRescanCategories: Bool) async {
        refreshVolumeCapacity()
        if autoRescanCategories {
            await runVolumeAnalysis()
        }
    }

    var canGoBack: Bool { !pathStack.isEmpty }

    var isFullDiskSession: Bool { pathStack.first?.path == "/" }

    var isShowingFolderBrowser: Bool { !pathStack.isEmpty }

    /// Запуск оценки занятого места по основным категориям (фоновая работа).
    func runVolumeAnalysis() async {
        isVolumeAnalyzing = true
        volumeAnalysisError = nil
        volumeAnalysisProgress = 0
        volumeAnalysisPhase = nil
        defer {
            isVolumeAnalyzing = false
            volumeAnalysisProgress = 1
        }

        do {
            let results = try await volumeScanner.scanAllCategories { @Sendable progress in
                Task { @MainActor in
                    self.volumeAnalysisProgress = progress.overallFraction
                    self.volumeAnalysisPhase = progress.currentCategory
                }
            }
            volumeCategoryTotals = results.sorted { $0.bytes > $1.bytes }
            let now = Date()
            lastCategorySnapshotAt = now
            MemoryOverviewPersistence.saveSnapshot(
                MemoryOverviewPersistence.Snapshot(scannedAt: now, categoryTotals: volumeCategoryTotals)
            )
            refreshVolumeCapacity()
        } catch {
            volumeAnalysisError = "Не удалось завершить анализ. Попробуйте ещё раз чуть позже."
        }
    }

    func returnToMemoryOverview() {
        pathStack.removeAll()
        items = []
        errorMessage = nil
        pinnedStorageCategory = nil
    }

    func openStorageCategory(_ category: StorageCategory) {
        pinnedStorageCategory = category
        let url = category.typicalRootURL()
        pathStack = [url]
        errorMessage = nil
        Task { await reloadListing() }
    }

    func pickFolder() {
        guard let url = FolderChooser.chooseFolder() else { return }
        let normalized = FolderPathScope.resolvingStandardDirectory(url)
        pathStack = [normalized]
        errorMessage = nil
        pinnedStorageCategory = nil
        Task { await reloadListing() }
    }

    func startFullDiskScan() {
        pathStack = [URL(fileURLWithPath: "/", isDirectory: true)]
        errorMessage = nil
        pinnedStorageCategory = nil
        Task { await reloadListing() }
    }

    func goBack() {
        guard !pathStack.isEmpty else { return }
        pathStack.removeLast()
        errorMessage = nil
        if pathStack.isEmpty {
            items = []
            return
        }
        Task { await reloadListing() }
    }

    func openDirectory(_ item: DirectoryListingItem) {
        guard item.isDirectory else { return }
        guard let root = pathStack.first else { return }

        let next = FolderPathScope.resolvingStandardDirectory(item.fileURL)
        guard FolderPathScope.isLocationInsideRoot(root: root, location: next) else {
            errorMessage = "Эту папку нельзя открыть: ярлык выводит за пределы текущего просмотра."
            return
        }

        pathStack.append(next)
        errorMessage = nil
        Task { await reloadListing() }
    }

    func canMoveItemToTrash(_ item: DirectoryListingItem, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        guard let root = pathStack.first else { return false }
        let itemPath = item.fileURL.standardizedFileURL.path
        if itemPath == "/" { return false }
        let homePath = home.standardizedFileURL.path
        // Из корня «/» не даём отправлять в корзину системные папки верхнего уровня — только объекты внутри домашней папки.
        if root.path == "/" {
            let underHome = itemPath == homePath || itemPath.hasPrefix(homePath + "/")
            if !underHome { return false }
        }
        if QuickCleanPathPolicy.isGloballyForbiddenForUserInitiatedTrash(path: item.path, home: home) {
            return false
        }
        return FolderPathScope.isLocationInsideRoot(root: root, location: item.fileURL)
    }

    /// Текущая открытая папка (адрес в шапке браузера) — те же правила, что и для строки-папки.
    func canMoveCurrentFolderToTrash(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        guard let url = selectedFolderURL else { return false }
        let item = DirectoryListingItem(
            name: url.lastPathComponent,
            path: url.path,
            isDirectory: true,
            sizeBytes: nil,
            safetyKind: .neutral
        )
        return canMoveItemToTrash(item, home: home)
    }

    func moveCurrentFolderToTrash() async -> String? {
        guard let current = pathStack.last, let root = pathStack.first else { return "Нет открытой папки." }
        if current.path == "/" { return "Корень диска нельзя отправить в корзину." }
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let synthetic = DirectoryListingItem(
            name: current.lastPathComponent,
            path: current.path,
            isDirectory: true,
            sizeBytes: nil,
            safetyKind: .neutral
        )
        guard canMoveItemToTrash(synthetic, home: home) else {
            return "Эту папку нельзя отправить в корзину из соображений безопасности или границ просмотра."
        }
        do {
            try await Task.detached(priority: .userInitiated) {
                try FolderBrowserTrash.moveToTrash(itemPath: current.path, root: root, home: home)
            }.value
            pathStack.removeLast()
            if pathStack.isEmpty {
                returnToMemoryOverview()
            } else {
                await reloadListing()
            }
            return nil
        } catch let err as FolderBrowserTrash.Error {
            return err.localizedDescription
        } catch {
            return error.localizedDescription
        }
    }

    func moveItemToTrash(_ item: DirectoryListingItem) async -> String? {
        guard let root = pathStack.first else { return "Нет открытой папки." }
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        do {
            try await Task.detached(priority: .userInitiated) {
                try FolderBrowserTrash.moveToTrash(itemPath: item.path, root: root, home: home)
            }.value
            await reloadListing()
            return nil
        } catch let err as FolderBrowserTrash.Error {
            return err.localizedDescription
        } catch {
            return error.localizedDescription
        }
    }

    func reloadListing() async {
        guard let url = pathStack.last else {
            return
        }
        isLoading = true
        errorMessage = nil
        startProgressTicker()
        defer {
            isLoading = false
            stopProgressTicker()
            loadProgressSamples = [1.0]
        }

        do {
            items = try await listing.listDirectChildren(of: url)
        } catch let listingError as DirectoryListingError {
            items = []
            errorMessage = listingError.localizedDescription
        } catch {
            items = []
            errorMessage = "Не удалось открыть содержимое папки."
        }
    }

    private func startProgressTicker() {
        stopProgressTicker()
        loadProgressStarted = Date()
        loadProgressSamples = [0]

        progressTicker = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let t0 = loadProgressStarted else { break }
                let elapsed = Date().timeIntervalSince(t0)
                let p = min(0.95, elapsed / 0.85)
                loadProgressSamples.append(p)
                if loadProgressSamples.count > 56 {
                    loadProgressSamples.removeFirst(loadProgressSamples.count - 56)
                }
            }
        }
    }

    private func stopProgressTicker() {
        progressTicker?.cancel()
        progressTicker = nil
        loadProgressStarted = nil
    }
}

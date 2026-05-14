import CleanerCore
import Foundation
import Observation

@MainActor
@Observable
final class ScanFolderViewModel {
    private let listing: ShallowDirectoryListingService

    /// Стек каталогов: первый — выбранный корень, последний — текущая папка.
    private var pathStack: [URL] = []

    /// Текущая открытая папка (для списка и заголовка пути).
    var selectedFolderURL: URL? { pathStack.last }

    /// Корень, выбранный через панель (для подписи «остаётся неизменным» при навигации).
    var rootFolderURL: URL? { pathStack.first }

    var items: [DirectoryListingItem] = []
    var isLoading = false
    var errorMessage: String?

    init(listing: ShallowDirectoryListingService = ShallowDirectoryListingService()) {
        self.listing = listing
    }

    var canGoBack: Bool { pathStack.count > 1 }

    func pickFolder() {
        guard let url = FolderChooser.chooseFolder() else { return }
        let normalized = FolderPathScope.resolvingStandardDirectory(url)
        pathStack = [normalized]
        errorMessage = nil
        Task { await reloadListing() }
    }

    func goBack() {
        guard canGoBack else { return }
        pathStack.removeLast()
        errorMessage = nil
        Task { await reloadListing() }
    }

    /// Открыть подкаталог текущего уровня (после проверки границы корня).
    func openDirectory(_ item: DirectoryListingItem) {
        guard item.isDirectory else { return }
        guard let root = pathStack.first else { return }

        let next = FolderPathScope.resolvingStandardDirectory(item.fileURL)
        guard FolderPathScope.isLocationInsideRoot(root: root, location: next) else {
            errorMessage = "Нельзя выйти за пределы выбранной папки (обнаружен симлинк или недопустимый путь)."
            return
        }

        pathStack.append(next)
        errorMessage = nil
        Task { await reloadListing() }
    }

    func reloadListing() async {
        guard let url = pathStack.last else {
            errorMessage = "Сначала выберите папку."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await listing.listDirectChildren(of: url)
        } catch let listingError as DirectoryListingError {
            items = []
            errorMessage = listingError.localizedDescription
        } catch {
            items = []
            errorMessage = "Не удалось прочитать папку: \(error.localizedDescription)"
        }
    }
}

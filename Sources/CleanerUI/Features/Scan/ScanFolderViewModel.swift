import CleanerCore
import Foundation
import Observation

@MainActor
@Observable
final class ScanFolderViewModel {
    private let listing: ShallowDirectoryListingService

    var selectedFolderURL: URL?
    var items: [DirectoryListingItem] = []
    var isLoading = false
    /// Сообщение об ошибке или подсказка; `nil` если всё в порядке.
    var errorMessage: String?

    init(listing: ShallowDirectoryListingService = ShallowDirectoryListingService()) {
        self.listing = listing
    }

    func pickFolder() {
        guard let url = FolderChooser.chooseFolder() else { return }
        selectedFolderURL = url.standardizedFileURL
        errorMessage = nil
        Task { await reloadListing() }
    }

    func reloadListing() async {
        guard let url = selectedFolderURL else {
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

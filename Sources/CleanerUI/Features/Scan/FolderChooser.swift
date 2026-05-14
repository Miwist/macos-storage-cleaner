import AppKit
import Foundation

/// Выбор каталога через системную панель (`NSOpenPanel`).
@MainActor
enum FolderChooser {
    /// Показывает модальную панель выбора папки. Вызывать с главного потока.
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Выбрать"
        panel.title = "Выберите папку"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}

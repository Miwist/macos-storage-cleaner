import CleanerCore
import SwiftUI

enum MemoryPresentation {
    static func title(for category: StorageCategory) -> String {
        switch category {
        case .applications: "Программы"
        case .downloads: "Загрузки"
        case .documents: "Документы"
        case .desktop: "Рабочий стол"
        case .pictures: "Фото"
        case .movies: "Видео"
        case .music: "Музыка"
        case .caches: "Кэши программ"
        case .developerTools: "Среда разработки"
        case .trash: "Корзина"
        }
    }

    static func symbol(for category: StorageCategory) -> String {
        switch category {
        case .applications: "app.badge.fill"
        case .downloads: "arrow.down.circle.fill"
        case .documents: "doc.text.fill"
        case .desktop: "macwindow"
        case .pictures: "photo.on.rectangle.angled"
        case .movies: "film.fill"
        case .music: "music.note.list"
        case .caches: "internaldrive.fill"
        case .developerTools: "hammer.fill"
        case .trash: "trash.fill"
        }
    }

    static func tint(for category: StorageCategory) -> Color {
        switch category {
        case .applications: .purple
        case .downloads: .blue
        case .documents: .teal
        case .desktop: .indigo
        case .pictures: .pink
        case .movies: .orange
        case .music: .red
        case .caches: .mint
        case .developerTools: .brown
        case .trash: .gray
        }
    }

    static func hint(for kind: StoragePathSafetyKind) -> String {
        switch kind {
        case .neutral: "Обычный элемент"
        case .relativelySafeCleanupCandidate: "Часто можно удалить"
        case .important: "Лучше не трогать"
        }
    }

    static func hintColor(for kind: StoragePathSafetyKind) -> Color {
        switch kind {
        case .neutral: .secondary
        case .relativelySafeCleanupCandidate: .green
        case .important: .orange
        }
    }
}

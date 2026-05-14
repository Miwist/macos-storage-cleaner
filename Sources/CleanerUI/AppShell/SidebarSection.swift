import SwiftUI

/// Разделы боковой панели главного окна. Новые экраны — новый кейс и заглушка в `Features/`.
enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case scan
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: "Сканирование"
        case .settings: "Настройки"
        case .about: "О программе"
        }
    }

    var systemImage: String {
        switch self {
        case .scan: "externaldrive"
        case .settings: "gearshape"
        case .about: "info.circle"
        }
    }
}

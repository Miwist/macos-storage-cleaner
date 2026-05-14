import SwiftUI

/// Разделы боковой панели главного окна. Новые экраны — новый кейс и заглушка в `Features/`.
enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case scan
    case quickClean
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: "Память"
        case .quickClean: "Быстрая очистка"
        case .settings: "Настройки"
        case .about: "О программе"
        }
    }

    var systemImage: String {
        switch self {
        case .scan: "chart.pie.fill"
        case .quickClean: "trash.circle"
        case .settings: "gearshape"
        case .about: "info.circle"
        }
    }
}

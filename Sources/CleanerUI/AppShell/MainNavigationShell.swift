import SwiftUI

/// Главное окно: боковая навигация и область контента. Без бизнес-логики сканирования.
struct MainNavigationShell: View {
    @State private var selection: SidebarSection? = .scan

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Очистка хранилища")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            Group {
                switch selection {
                case .scan:
                    ScanView()
                case .settings:
                    SettingsView()
                case .about:
                    AboutView()
                case .none:
                    ContentUnavailableView(
                        "Выберите раздел",
                        systemImage: "sidebar.left",
                        description: Text("Пункт в списке слева.")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

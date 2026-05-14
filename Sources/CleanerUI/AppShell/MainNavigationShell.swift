import SwiftUI

/// Главное окно: боковая навигация и область контента. Без бизнес-логики сканирования.
struct MainNavigationShell: View {
    @State private var selection: SidebarSection? = .scan
    @AppStorage("colorfulInterface") private var colorfulInterface = true

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Очистка хранилища")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .scrollContentBackground(.hidden)
            .background(sidebarBackground)
        } detail: {
            Group {
                switch selection {
                case .scan:
                    ScanView()
                case .quickClean:
                    QuickCleanView()
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

    private var sidebarBackground: some View {
        Group {
            if colorfulInterface {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.14),
                        Color.purple.opacity(0.08),
                        Color.clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
            }
        }
    }
}

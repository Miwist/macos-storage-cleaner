import SwiftUI

/// Корневой контейнер главного окна. Точка входа UI для модуля `CleanerApp`.
public struct RootView: View {
    public init() {}

    public var body: some View {
        MainNavigationShell()
            .frame(minWidth: 720, minHeight: 480)
    }
}

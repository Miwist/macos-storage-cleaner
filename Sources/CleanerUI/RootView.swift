import CleanerCore
import SwiftUI

public struct RootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("Очистка хранилища macOS")
                .font(.title2)
            Text("Каркас приложения. Логика сканирования — в следующих задачах.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
            Text("Модуль: \(CleanerCore.bundleName)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(minWidth: 480, minHeight: 280)
    }
}

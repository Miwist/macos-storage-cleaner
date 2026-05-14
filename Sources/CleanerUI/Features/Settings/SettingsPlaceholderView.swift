import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Параметры приложения и доступа к диску появятся здесь. Скоро.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Настройки")
    }
}

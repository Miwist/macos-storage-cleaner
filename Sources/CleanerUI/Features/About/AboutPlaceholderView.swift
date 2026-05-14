import CleanerCore
import SwiftUI

struct AboutPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("О программе")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Версия, лицензия и ссылки на репозиторий — скоро.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480, alignment: .leading)
            Text("Сборка: \(CleanerCore.bundleName)")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("О программе")
    }
}

import SwiftUI

struct ScanPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сканирование")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Здесь будет выбор папок и отображение занятого места. Скоро.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Сканирование")
    }
}

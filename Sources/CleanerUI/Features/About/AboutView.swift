import CleanerCore
import SwiftUI

struct AboutView: View {
    private var repositoryURL: URL? {
        URL(string: AppMetadata.repositoryPageURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Очистка хранилища macOS")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Group {
                LabeledContent("Версия", value: AppMetadata.marketingVersion)
                LabeledContent("Лицензия", value: AppMetadata.licenseName)
            }
            .font(.body)

            if let url = repositoryURL {
                Link(destination: url) {
                    Label("Открыть страницу проекта", systemImage: "link")
                }
                .buttonStyle(.borderedProminent)
            }

            Text(
                "Приложение помогает понять, что занимает место на диске, показывает основные разделы и даёт аккуратные подсказки. Удаление выполняется только вашими действиями."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 520, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("О программе")
    }
}

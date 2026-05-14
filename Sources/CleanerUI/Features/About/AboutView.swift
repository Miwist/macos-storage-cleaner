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
                LabeledContent("Исполняемый модуль", value: CleanerCore.bundleName)
                LabeledContent("Лицензия", value: "\(AppMetadata.licenseName) (см. файл LICENSE в репозитории)")
            }
            .font(.body)

            if let url = repositoryURL {
                Link(destination: url) {
                    Label("Репозиторий на GitHub", systemImage: "link")
                }
                .buttonStyle(.borderedProminent)
            }

            Text("Приложение помогает просматривать занятое место в выбранных папках. Удаление и глубокий анализ системы могут появиться в следующих версиях.")
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

import CleanerCore
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("О приложении") {
                LabeledContent("Название", value: "Очистка хранилища macOS")
                LabeledContent("Версия", value: AppMetadata.marketingVersion)
            }

            Section("Доступ к файлам") {
                Text(
                    "Для чтения некоторых каталогов (например, чужие защищённые пути) macOS может запретить доступ. При необходимости добавьте приложение в «Системные настройки» → «Конфиденциальность и безопасность» → «Полный доступ к диску». Этот MVP не запрашивает разрешение автоматически."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section("Сканирование") {
                Text(
                    "Выберите папку в разделе «Сканирование». Навигация внутрь и кнопка «Назад» работают только внутри выбранного корня; размеры файлов на текущем уровне считаются в модуле CleanerCore."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section("Лицензия") {
                Text("Открытый исходный код под лицензией \(AppMetadata.licenseName). Подробности в репозитории проекта.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Настройки")
    }
}

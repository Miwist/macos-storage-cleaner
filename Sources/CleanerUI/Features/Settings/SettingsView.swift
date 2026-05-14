import CleanerCore
import SwiftUI

struct SettingsView: View {
    @AppStorage("showPathSafetyHighlights") private var showPathSafetyHighlights = true
    @AppStorage("autoAnalyzeStorageOnOpen") private var autoAnalyzeStorageOnOpen = true
    @AppStorage("showTechnicalPaths") private var showTechnicalPaths = false
    @AppStorage("colorfulInterface") private var colorfulInterface = true
    @AppStorage("confirmBeforeMoveToTrash") private var confirmBeforeMoveToTrash = true

    var body: some View {
        Form {
            Section("О приложении") {
                LabeledContent("Название", value: "Очистка хранилища macOS")
                LabeledContent("Версия", value: AppMetadata.marketingVersion)
            }

            Section("Память и корзина") {
                Toggle(
                    "Спрашивать подтверждение перед «Переместить в корзину» в разделе «Память»",
                    isOn: $confirmBeforeMoveToTrash
                )
                Text("Если выключить, выбранный файл или папка сразу отправляются в корзину Finder из контекстного меню таблицы.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

            Section("Анализ памяти") {
                Toggle("Считать основные папки при открытии раздела «Память»", isOn: $autoAnalyzeStorageOnOpen)
                Text(
                    "Мы оцениваем загрузки, документы, кэши и другие типичные места. Это может занять от нескольких секунд до пары минут. Если выключить автоматический подсчёт, при открытии раздела покажем последний сохранённый снимок; заново посчитать можно кнопкой «Обновить оценку»."
                )
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Подсказки по файлам") {
                Toggle("Показывать подсказки «часто можно удалить» / «лучше не трогать»", isOn: $showPathSafetyHighlights)
                Text("Это оценка, а не гарантия. Перед удалением всё равно смотрите, что внутри папки.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Внешний вид") {
                Toggle("Больше цвета и мягкий фон", isOn: $colorfulInterface)
                Toggle("Показывать служебные пути macOS мелким шрифтом", isOn: $showTechnicalPaths)
                Text("Служебные пути полезны, если вы привыкли к терминалу; обычно они не нужны.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Доступ macOS") {
                Text(
                    "Если какая-то папка не открывается, откройте «Системные настройки» → «Конфиденциальность и безопасность» → «Полный доступ к диску» и добавьте это приложение. Мы не запрашиваем доступ сами — так спокойнее и прозрачнее."
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

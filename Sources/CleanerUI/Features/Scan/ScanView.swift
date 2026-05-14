import CleanerCore
import SwiftUI

struct ScanView: View {
    @State private var model = ScanFolderViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if let message = model.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                Divider()
            }
            content
        }
        .navigationTitle("Сканирование")
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button("Выбрать папку…") {
                model.pickFolder()
            }
            .keyboardShortcut("o", modifiers: [.command])

            if model.selectedFolderURL != nil {
                Button {
                    Task { await model.reloadListing() }
                } label: {
                    Label("Обновить", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading)
            }

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Чтение…")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer(minLength: 0)

            if let folder = model.selectedFolderURL {
                Text(folder.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var content: some View {
        if model.selectedFolderURL == nil {
            ContentUnavailableView(
                "Папка не выбрана",
                systemImage: "folder",
                description: Text("Нажмите «Выбрать папку…», чтобы показать элементы первого уровня и их размеры.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.isLoading && model.items.isEmpty {
            ProgressView("Загрузка содержимого…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage != nil {
            ContentUnavailableView(
                "Не удалось прочитать папку",
                systemImage: "exclamationmark.triangle",
                description: Text("См. сообщение выше. При нехватке прав проверьте настройки конфиденциальности macOS.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage == nil {
            ContentUnavailableView(
                "Пусто",
                systemImage: "doc",
                description: Text("В этой папке нет элементов (первый уровень).")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(model.items) {
                TableColumn("Имя") { item in
                    Label(item.name, systemImage: item.isDirectory ? "folder.fill" : "doc")
                }
                .width(min: 180, ideal: 280)
                TableColumn("Размер") { item in
                    Text(item.sizeDisplayString())
                        .monospacedDigit()
                }
                .width(min: 72, ideal: 100)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

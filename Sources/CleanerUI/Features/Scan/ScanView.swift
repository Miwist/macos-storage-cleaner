import CleanerCore
import SwiftUI

struct ScanView: View {
    @State private var model = ScanFolderViewModel()
    @State private var selectedItemIDs = Set<String>()

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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button("Выбрать папку…") {
                    selectedItemIDs = []
                    model.pickFolder()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button {
                    model.goBack()
                    selectedItemIDs = []
                } label: {
                    Label("Назад", systemImage: "chevron.backward")
                }
                .disabled(!model.canGoBack || model.isLoading)
                .help("Вернуться на уровень выше (до выбранного корня)")

                Button("Открыть") {
                    openSelectedFolder()
                }
                .disabled(!canOpenSelection || model.isLoading)
                .keyboardShortcut(.return, modifiers: [.command])

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
            }

            if let current = model.selectedFolderURL {
                VStack(alignment: .leading, spacing: 4) {
                    if let root = model.rootFolderURL, model.canGoBack {
                        Text("Корень: \(root.path)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                    Text(current.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(12)
    }

    private var canOpenSelection: Bool {
        guard selectedItemIDs.count == 1,
              let id = selectedItemIDs.first,
              let item = model.items.first(where: { $0.id == id })
        else { return false }
        return item.isDirectory
    }

    private func openSelectedFolder() {
        guard let id = selectedItemIDs.first,
              let item = model.items.first(where: { $0.id == id }),
              item.isDirectory
        else { return }
        selectedItemIDs = []
        model.openDirectory(item)
    }

    @ViewBuilder
    private var content: some View {
        if model.selectedFolderURL == nil {
            ContentUnavailableView(
                "Папка не выбрана",
                systemImage: "folder",
                description: Text("Выберите корневую папку, затем открывайте вложенные каталоги двойным щелчком по имени или кнопкой «Открыть».")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.isLoading && model.items.isEmpty {
            ProgressView("Загрузка содержимого…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage != nil {
            ContentUnavailableView(
                "Не удалось прочитать папку",
                systemImage: "exclamationmark.triangle",
                description: Text("См. сообщение выше.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !model.isLoading && model.items.isEmpty && model.errorMessage == nil {
            ContentUnavailableView(
                "Пусто",
                systemImage: "doc",
                description: Text("В этой папке нет элементов.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(model.items, selection: $selectedItemIDs) {
                TableColumn("Имя") { item in
                    Label(item.name, systemImage: item.isDirectory ? "folder.fill" : "doc")
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if item.isDirectory {
                                selectedItemIDs = []
                                model.openDirectory(item)
                            }
                        }
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

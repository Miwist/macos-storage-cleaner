# Очистка хранилища macOS

[![CI](https://github.com/Miwist/macos-storage-cleaner/actions/workflows/ci.yml/badge.svg)](https://github.com/Miwist/macos-storage-cleaner/actions/workflows/ci.yml)
[![Релиз](https://img.shields.io/github/v/release/Miwist/macos-storage-cleaner?label=релиз)](https://github.com/Miwist/macos-storage-cleaner/releases/latest)
[![Лицензия MIT](https://img.shields.io/github/license/Miwist/macos-storage-cleaner)](https://github.com/Miwist/macos-storage-cleaner/blob/main/LICENSE)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![SPM](https://img.shields.io/badge/пакет-Swift%20Package%20Manager-F05138?logo=swift&logoColor=white)](Package.swift)

**Нативное приложение для macOS:** просмотр занятого места в выбранной папке (вход в подкаталоги, «Назад» до корня, размеры файлов на текущем уровне) и дальнейшее развитие в сторону безопасного освобождения диска. Стек: **Swift**, **SwiftUI**, **Swift Package Manager**. Репозиторий: [github.com/Miwist/macos-storage-cleaner](https://github.com/Miwist/macos-storage-cleaner). **Готовую сборку для ноутбука** — синяя кнопка в разделе [«Скачать и установить»](#скачать-и-установить-готовая-сборка) ниже: по ней сразу качается ZIP с приложением.

## Описание

Проект ведётся **от спецификации** (см. `docs/СПЕЦИФИКАЦИЯ.md`): сначала фиксируем требования и критерии приёмки, затем код и коммиты с привязкой к номеру задачи.

Модули:

- **CleanerCore** — домен и сценарии без SwiftUI.
- **CleanerUI** — представления SwiftUI.
- **CleanerApp** — точка входа `@main`, сборка исполняемого продукта **MacosStorageCleaner**.

### Структура UI в коде

В модуле `CleanerUI` (см. `docs/СПЕЦИФИКАЦИЯ.md`, п. 3.1):

- `AppShell/` — главное окно и навигация (`NavigationSplitView`).
- `Features/<Раздел>/` — экраны по разделам; сканирование: `ScanView`, `ScanFolderViewModel`, `FolderChooser`; «О программе»: `AboutView`; «Настройки»: `SettingsView`.

## Требования

- macOS **14** или новее  
- **Xcode 15+** (Swift 5.9+) — только если собираете из исходников

## Скачать и установить (готовая сборка)

### Одна кнопка — скачать на Mac

[![Установить: скачать ZIP](https://img.shields.io/badge/Установить_на_Mac—скачать_.zip-006DBC?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/Miwist/macos-storage-cleaner/releases/latest/download/MacosStorageCleaner-macos.zip)

Это **прямая ссылка** на файл последнего релиза: Safari или Chrome сохранят **`MacosStorageCleaner-macos.zip`** в папку «Загрузки». Дальше:

1. Откройте архив двойным щелчком (получите **`MacosStorageCleaner.app`**).
2. Перетащите приложение в **«Программы»** или запускайте из окна архива.
3. **Первый запуск:** приложение без подписи Apple — **ПКМ по иконке** → **«Открыть»** → подтвердить; либо **Системные настройки** → **Конфиденциальность и безопасность** → **«Всё равно открыть»** после первой попытки запуска.

Версия сборки указана внутри приложения (**«О программе»**). Альтернатива: открыть [страницу релизов](https://github.com/Miwist/macos-storage-cleaner/releases/latest) и вручную выбрать архив (там же может лежать копия с номером версии в имени файла).

Сборка для GitHub появляется при push **git-тега** `v*` (см. [CONTRIBUTING.md](CONTRIBUTING.md)). Пока **нет ни одного релиза**, прямая ссылка на скачивание вернёт ошибку — откройте [релизы](https://github.com/Miwist/macos-storage-cleaner/releases) после первой публикации.

## Сборка и запуск

```bash
git clone https://github.com/Miwist/macos-storage-cleaner.git
cd macos-storage-cleaner
swift build
swift run MacosStorageCleaner
```

**Релизная сборка** (оптимизации компилятора):

```bash
swift build -c release
```

Исполняемый файл: `$(swift build -c release --show-bin-path)/MacosStorageCleaner` (можно запускать напрямую или через `swift run -c release MacosStorageCleaner`).

**Локальная упаковка в `.app` и ZIP** (как для GitHub Releases):

```bash
./scripts/package-macos-app.sh
```

Архивы появятся в `.build/`: **`MacosStorageCleaner-macos.zip`** (то же содержимое, стабильное имя для ссылки *latest/download*) и **`MacosStorageCleaner-<версия>-macos.zip`**.

Либо откройте `Package.swift` в Xcode и нажмите **Run** (схема **MacosStorageCleaner**).

## Лицензия

См. [LICENSE](LICENSE) (MIT). Кратко: можно свободно использовать и изменять при сохранении уведомления об авторских правах.

## Участие

См. [CONTRIBUTING.md](CONTRIBUTING.md) и [SECURITY.md](SECURITY.md).

## Вспомогательные файлы

- **`.gitignore`** — не коммитить сборку и артефакты Xcode.
- **`.cursorignore`** — исключения для индексации в Cursor.
- **`.dockerignore`** — на будущее, если появится контейнеризация.

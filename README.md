# Очистка хранилища macOS

[![CI](https://github.com/Miwist/macos-storage-cleaner/actions/workflows/ci.yml/badge.svg)](https://github.com/Miwist/macos-storage-cleaner/actions/workflows/ci.yml)
[![Лицензия MIT](https://img.shields.io/github/license/Miwist/macos-storage-cleaner)](https://github.com/Miwist/macos-storage-cleaner/blob/main/LICENSE)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![SPM](https://img.shields.io/badge/пакет-Swift%20Package%20Manager-F05138?logo=swift&logoColor=white)](Package.swift)

**Нативное приложение для macOS:** просмотр занятого места и безопасное освобождение диска. Стек: **Swift**, **SwiftUI**, модульная структура (**Swift Package Manager**). Репозиторий: [github.com/Miwist/macos-storage-cleaner](https://github.com/Miwist/macos-storage-cleaner).

## Описание

Проект ведётся **от спецификации** (см. `docs/СПЕЦИФИКАЦИЯ.md`): сначала фиксируем требования и критерии приёмки, затем код и коммиты с привязкой к номеру задачи.

Модули:

- **CleanerCore** — домен и сценарии без SwiftUI.
- **CleanerUI** — представления SwiftUI.
- **CleanerApp** — точка входа `@main`, сборка исполняемого продукта **MacosStorageCleaner**.

### Структура UI в коде

В модуле `CleanerUI` (см. `docs/СПЕЦИФИКАЦИЯ.md`, п. 3.1):

- `AppShell/` — главное окно и навигация (`NavigationSplitView`).
- `Features/<Раздел>/` — экраны и заглушки по разделам (например `Features/Scan/`).

## Требования

- macOS **14** или новее  
- **Xcode 15+** (Swift 5.9+)

## Сборка и запуск

```bash
git clone https://github.com/Miwist/macos-storage-cleaner.git
cd macos-storage-cleaner
swift build
swift run MacosStorageCleaner
```

Либо откройте `Package.swift` в Xcode и нажмите **Run** (схема **MacosStorageCleaner**).

## Лицензия

См. [LICENSE](LICENSE) (MIT). Кратко: можно свободно использовать и изменять при сохранении уведомления об авторских правах.

## Участие

См. [CONTRIBUTING.md](CONTRIBUTING.md) и [SECURITY.md](SECURITY.md).

## Вспомогательные файлы

- **`.gitignore`** — не коммитить сборку и артефакты Xcode.  
- **`.cursorignore`** — исключения для индексации в Cursor.  
- **`.dockerignore`** — на будущее, если появится контейнеризация.

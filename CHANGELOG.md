# Журнал изменений

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

## [Не выпущено]

### Добавлено

- Скрипт **`scripts/package-macos-app.sh`**: релизная сборка и ZIP с `MacosStorageCleaner.app` для GitHub Releases; workflow **`.github/workflows/release.yml`** публикует архив при push тега `v*`.
- В README: раздел «Скачать и установить», бейдж релиза, актуальные пути к бинарнику после `swift build -c release`.
- Навигация внутри выбранного корня: стек каталогов, «Назад», двойной щелчок и «Открыть» для папок, полный путь и подпись корня.
- В `CleanerCore`: `FolderPathScope` (границы навигации), `AppMetadata` (версия MVP, ссылка на репозиторий, лицензия).
- Экраны **«О программе»** (`AboutView`) и **«Настройки»** (`SettingsView`) с осмысленным MVP-контентом.

### Ранее

- Раздел «Сканирование» (задача #3): `NSOpenPanel`, таблица первого уровня, `ShallowDirectoryListingService`, исправления CI.
- Модульный Swift Package, спека, правила Cursor, документация для участников.

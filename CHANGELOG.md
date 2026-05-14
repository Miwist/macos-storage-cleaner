# Журнал изменений

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

## [Не выпущено]

### Добавлено

- Раздел «Сканирование»: выбор папки через `NSOpenPanel`, таблица прямых вложений, размеры файлов, фоновое чтение (`ShallowDirectoryListingService`).
- Модели и ошибки листинга в `CleanerCore` (`DirectoryListingItem`, `DirectoryListingError`, `ByteSizeFormatting`).

### Исправлено

- CI: `Sendable`-модели листинга хранят путь как `String` (совместимость со Swift 5.9 на `macos-14`); workflow на `macos-15` и `actions/checkout@v5`.

### Ранее

- Модульный Swift Package: `CleanerCore`, `CleanerUI`, исполняемый `CleanerApp`.
- Базовая спецификация и правила для Cursor.
- Документация для участников и шаблон CI.

import Foundation

/// Человекочитаемый размер (КБ / МБ / ГБ) с предсказуемым русским текстом для краевых значений.
public enum ByteSizeFormatting: Sendable {
    public static func string(forByteCount bytes: Int64) -> String {
        if bytes < 0 { return "—" }
        if bytes == 0 { return "0 байт" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .file
        let s = formatter.string(fromByteCount: bytes)
        // На некоторых системах для 0 приходит англ. «Zero KB» — перехватываем.
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("zero") || trimmed == "0 КБ" || trimmed == "0 KB" {
            return "0 байт"
        }
        return s
    }

    /// Для опционального размера (например, папка без оценки).
    public static func string(forOptionalByteCount bytes: Int64?, missing: String = "—") -> String {
        guard let bytes else { return missing }
        return string(forByteCount: bytes)
    }
}

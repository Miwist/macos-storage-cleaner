import Charts
import CleanerCore

extension StorageCategory: Plottable {
    public var primitivePlottable: String { rawValue }

    public init?(primitivePlottable: String) {
        self.init(rawValue: primitivePlottable)
    }
}

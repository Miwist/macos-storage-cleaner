import Foundation

public struct StorageCategoryTotal: Sendable, Identifiable, Equatable, Codable {
    public let category: StorageCategory
    public let bytes: Int64

    public var id: String { category.rawValue }

    public init(category: StorageCategory, bytes: Int64) {
        self.category = category
        self.bytes = bytes
    }
}

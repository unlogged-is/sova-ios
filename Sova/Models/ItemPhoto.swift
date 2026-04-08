import Foundation
import SwiftData

@Model
final class ItemPhoto {
    @Attribute(.externalStorage) var data: Data?
    var createdAt: Date = Date()
    var item: MaintenanceItem?

    init(data: Data?, createdAt: Date = Date(), item: MaintenanceItem? = nil) {
        self.data = data
        self.createdAt = createdAt
        self.item = item
    }
}

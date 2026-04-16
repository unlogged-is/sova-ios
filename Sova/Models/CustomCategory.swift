import Foundation
import SwiftData

@Model
final class CustomCategory {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "folder.fill"
    var tintName: String = "accentPrimary"
    var createdAt: Date = Date()

    init(
        name: String,
        symbolName: String = "folder.fill",
        tintName: String = "accentPrimary"
    ) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.tintName = tintName
        self.createdAt = Date()
    }

    var tintColor: Color {
        switch tintName {
        case "accentPrimary": .sovaPrimaryAccent
        case "accentWarm": .sovaWarmAccent
        case "dueSoon": .sovaDueSoon
        default: .sovaSecondaryText
        }
    }

    /// Available icons for custom categories
    static let availableIcons: [(name: String, symbol: String)] = [
        ("Folder", "folder.fill"),
        ("Tool", "wrench.and.screwdriver.fill"),
        ("Star", "star.fill"),
        ("Heart", "heart.fill"),
        ("Bolt", "bolt.fill"),
        ("Flame", "flame.fill"),
        ("Drop", "drop.fill"),
        ("Laptop", "laptopcomputer"),
        ("Phone", "iphone"),
        ("TV", "tv.fill"),
        ("Camera", "camera.fill"),
        ("Headphones", "headphones"),
        ("Gamepad", "gamecontroller.fill"),
        ("Guitar", "guitars.fill"),
        ("Book", "book.fill"),
        ("Briefcase", "briefcase.fill"),
        ("Tag", "tag.fill"),
        ("Key", "key.fill"),
        ("Lock", "lock.fill"),
        ("Gift", "gift.fill"),
        ("Cart", "cart.fill"),
        ("Box", "shippingbox.fill"),
        ("Paw", "pawprint.fill"),
        ("Trophy", "trophy.fill"),
    ]

    /// Available tint options
    static let availableTints: [(name: String, key: String)] = [
        ("Green", "accentPrimary"),
        ("Warm", "accentWarm"),
        ("Gold", "dueSoon"),
        ("Gray", "textSecondary"),
    ]
}

import SwiftUI

import Foundation

// MARK: - Field Type

enum CategoryFieldType: String, Codable {
    case text
    case number
    case date
}

// MARK: - Field Definition

struct CategoryFieldDefinition: Identifiable {
    let key: String
    let label: String
    let fieldType: CategoryFieldType

    var id: String { key }

    static func fields(for category: SovaCategory, usesMetricUnits: Bool = false) -> [CategoryFieldDefinition] {
        switch category {
        case .car:
            [
                .init(key: "make", label: "Make", fieldType: .text),
                .init(key: "model", label: "Model", fieldType: .text),
                .init(key: "year", label: "Year", fieldType: .number),
                .init(key: "plateNumber", label: "Plate Number", fieldType: .text),
                .init(key: "vin", label: "VIN", fieldType: .text),
                .init(key: "mileage", label: usesMetricUnits ? "Mileage (km)" : "Mileage (mi)", fieldType: .number),
            ]
        case .appliance:
            [
                .init(key: "brand", label: "Brand", fieldType: .text),
                .init(key: "modelNumber", label: "Model Number", fieldType: .text),
                .init(key: "serialNumber", label: "Serial Number", fieldType: .text),
            ]
        case .hvac:
            [
                .init(key: "systemType", label: "System Type", fieldType: .text),
                .init(key: "filterSize", label: "Filter Size", fieldType: .text),
                .init(key: "seerRating", label: "SEER Rating", fieldType: .number),
            ]
        case .bike:
            [
                .init(key: "brand", label: "Brand", fieldType: .text),
                .init(key: "model", label: "Model", fieldType: .text),
                .init(key: "year", label: "Year", fieldType: .number),
                .init(key: "frameSize", label: "Frame Size", fieldType: .text),
                .init(key: "serialNumber", label: "Serial Number", fieldType: .text),
                .init(key: "mileage", label: usesMetricUnits ? "Mileage (km)" : "Mileage (mi)", fieldType: .number),
            ]
        case .home:
            []
        case .garden:
            [
                .init(key: "plantType", label: "Plant Type", fieldType: .text),
                .init(key: "zone", label: "Zone", fieldType: .text),
                .init(key: "season", label: "Season", fieldType: .text),
            ]
        case .warranty:
            [
                .init(key: "provider", label: "Provider", fieldType: .text),
                .init(key: "policyNumber", label: "Policy Number", fieldType: .text),
                .init(key: "expirationDate", label: "Expiration Date", fieldType: .date),
            ]
        case .receipt:
            [
                .init(key: "store", label: "Store", fieldType: .text),
                .init(key: "amount", label: "Amount", fieldType: .text),
                .init(key: "receiptDate", label: "Receipt Date", fieldType: .date),
                .init(key: "paymentMethod", label: "Payment Method", fieldType: .text),
                .init(key: "returnBy", label: "Return By", fieldType: .date),
            ]
        case .other:
            []
        }
    }
}

// MARK: - Service Suggestions per Category

extension SovaCategory {
    /// Common service/maintenance actions for this category
    var serviceSuggestions: [String] {
        switch self {
        case .car:
            ["Oil Change", "Tire Rotation", "Brake Service", "Transmission Service",
             "Coolant Flush", "Air Filter", "Battery Replacement", "Inspection", "Car Wash"]
        case .appliance:
            ["Cleaning", "Filter Replacement", "Inspection", "Repair", "Descaling"]
        case .hvac:
            ["Filter Change", "Inspection", "Coil Cleaning", "Refrigerant Check", "Duct Cleaning"]
        case .bike:
            ["Tune-up", "Tire Change", "Chain Lube", "Brake Adjustment", "Cable Replacement",
             "Wheel Truing", "Gear Adjustment", "Tire Pressure Check", "Full Service"]
        case .home:
            ["Cleaning", "Repair", "Painting", "Inspection", "Pest Control",
             "Gutter Cleaning", "Roof Inspection", "Lawn Treatment"]
        case .garden:
            ["Watering", "Pruning", "Fertilizing", "Pest Treatment", "Mulching"]
        case .warranty:
            ["Claim Filed", "Renewal"]
        case .receipt:
            ["Return", "Exchange"]
        case .other:
            ["General Service", "Inspection", "Repair"]
        }
    }
}

// MARK: - Reminder Draft (for form editing)

struct ReminderDraft: Identifiable {
    let id: UUID
    var name: String
    var nextDueDate: Date
    var intervalMonths: Int
    var lastServiceDate: Date?
    var isComplete: Bool
    var existingReminder: ItemReminder?

    init(
        id: UUID = UUID(),
        name: String = "",
        nextDueDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now,
        intervalMonths: Int = 6,
        lastServiceDate: Date? = nil,
        isComplete: Bool = false,
        existingReminder: ItemReminder? = nil
    ) {
        self.id = id
        self.name = name
        self.nextDueDate = nextDueDate
        self.intervalMonths = intervalMonths
        self.lastServiceDate = lastServiceDate
        self.isComplete = isComplete
        self.existingReminder = existingReminder
    }

    init(from reminder: ItemReminder) {
        self.id = UUID()
        self.name = reminder.name
        self.nextDueDate = reminder.nextDueDate ?? Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
        self.intervalMonths = reminder.intervalMonths ?? 6
        self.lastServiceDate = reminder.lastServiceDate
        self.isComplete = reminder.isComplete
        self.existingReminder = reminder
    }
}

// MARK: - Home Field Keys

enum HomeFieldKeys {
    static let street = "address_street"
    static let city = "address_city"
    static let state = "address_state"
    static let zip = "address_zip"
    static let roomCount = "roomCount"
    static func roomName(_ index: Int) -> String { "room_\(index)_name" }
    static func roomSqft(_ index: Int) -> String { "room_\(index)_sqft" }

    // Legacy keys
    static let legacyAreaRoom = "areaRoom"
    static let legacySquareFootage = "squareFootage"
}

// MARK: - Room Draft (for form editing)

struct RoomDraft: Identifiable {
    let id: UUID
    var name: String
    var squareFootage: String

    init(id: UUID = UUID(), name: String = "", squareFootage: String = "") {
        self.id = id
        self.name = name
        self.squareFootage = squareFootage
    }
}

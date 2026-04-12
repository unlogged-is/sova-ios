import SwiftData
import SwiftUI

struct LogServiceView: View {
    let item: MaintenanceItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedServices: Set<String> = []
    @State private var customService: String = ""
    @State private var serviceDate: Date = .now
    @State private var serviceNotes: String = ""
    @State private var nextServiceDates: [String: Date] = [:]
    @State private var updatedMileage: String = ""
    @State private var previousMileage: String = ""
    @FocusState private var isMileageFocused: Bool
    @State private var serviceLocation: String = ""
    @AppStorage("usesMetricUnits") private var usesMetricUnits: Bool = false

    private var suggestions: [String] {
        item.category.serviceSuggestions
    }

    private var isCustomSelected: Bool {
        selectedServices.contains("Custom")
    }

    /// All resolved service names in stable order (matching suggestions list order, custom last)
    private var resolvedServiceNames: [String] {
        var names: [String] = []
        // Add selected suggestions in their original order
        for suggestion in suggestions where selectedServices.contains(suggestion) {
            names.append(suggestion)
        }
        // Add custom entry last
        if isCustomSelected {
            let trimmed = customService.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { names.append(trimmed) }
        }
        return names
    }

    private func defaultNextDate(for serviceName: String = "") -> Date {
        let months = defaultIntervalMonths(for: serviceName)
        return Calendar.current.date(byAdding: .month, value: months, to: serviceDate) ?? serviceDate
    }

    private func defaultIntervalMonths(for serviceName: String) -> Int {
        switch serviceName {
        case "Oil Change": return 3
        case "Tire Rotation": return 6
        case "Air Filter": return 12
        case "Brake Service": return 12
        case "Filter Change": return 3
        default: return 6
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Service type picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What was done?")
                            .font(SovaFont.title(.title3))
                            .foregroundStyle(.sovaPrimaryText)

                        FlowLayout(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                serviceChip(suggestion)
                            }
                            serviceChip("Custom")
                        }

                        if isCustomSelected {
                            TextField("Service name", text: $customService)
                                .font(SovaFont.body(.body))
                                .padding(12)
                                .background(.sovaSurface, in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(.sovaSurface, in: .rect(cornerRadius: 28))

                    // Service date & notes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(SovaFont.title(.title3))
                            .foregroundStyle(.sovaPrimaryText)

                        DatePicker("Service date", selection: $serviceDate, displayedComponents: .date)
                            .font(SovaFont.body(.body))

                        if item.category == .car {
                            HStack {
                                Text(usesMetricUnits ? "Current odometer (km)" : "Current mileage (mi)")
                                    .font(SovaFont.body(.body))
                                    .foregroundStyle(.sovaPrimaryText)
                                Spacer()
                                TextField("e.g. 45000", text: $updatedMileage)
                                    .font(SovaFont.body(.body))
                                    .foregroundStyle(.sovaPrimaryText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isMileageFocused)
                                    .onChange(of: isMileageFocused) { _, focused in
                                        if focused {
                                            previousMileage = updatedMileage
                                            updatedMileage = ""
                                        } else if updatedMileage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            updatedMileage = previousMileage
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(width: 130)
                                    .background(.sovaSurface.opacity(0.5), in: .rect(cornerRadius: 10))
                            }

                            HStack {
                                Text("Done at")
                                    .font(SovaFont.body(.body))
                                    .foregroundStyle(.sovaPrimaryText)
                                Spacer()
                                TextField("e.g. Jiffy Lube", text: $serviceLocation)
                                    .font(SovaFont.body(.body))
                                    .foregroundStyle(.sovaPrimaryText)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(width: 180)
                                    .background(.sovaSurface.opacity(0.5), in: .rect(cornerRadius: 10))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(SovaFont.mono(.caption))
                                .foregroundStyle(.sovaSecondaryText)
                            TextField("Optional notes about this service", text: $serviceNotes, axis: .vertical)
                                .font(SovaFont.body(.body))
                                .lineLimit(3...6)
                                .padding(12)
                                .background(.sovaSurface.opacity(0.5), in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(.sovaSurface, in: .rect(cornerRadius: 28))

                    // Per-service next due dates
                    if !resolvedServiceNames.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Next Service Dates")
                                .font(SovaFont.title(.title3))
                                .foregroundStyle(.sovaPrimaryText)

                            let names = resolvedServiceNames
                            ForEach(Array(names.enumerated()), id: \.element) { index, name in
                                nextDateRow(for: name, isLast: index == names.count - 1)
                            }
                        }
                        .padding(20)
                        .background(.sovaSurface, in: .rect(cornerRadius: 28))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(.sovaBackground)
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { logService() }
                        .disabled(resolvedServiceNames.isEmpty)
                }
            }
            .onAppear {
                if item.category == .car {
                    updatedMileage = item.customFields["mileage"] ?? ""
                }
            }
        }
    }

    // MARK: - Chip

    private func serviceChip(_ label: String) -> some View {
        let isSelected = selectedServices.contains(label)
        return Button {
            withAnimation(SovaAccessibility.animation(.snappy(duration: 0.2))) {
                if isSelected {
                    selectedServices.remove(label)
                    // Clean up next date entry
                    if label == "Custom" {
                        let trimmed = customService.trimmingCharacters(in: .whitespacesAndNewlines)
                        nextServiceDates.removeValue(forKey: trimmed)
                    } else {
                        nextServiceDates.removeValue(forKey: label)
                    }
                } else {
                    selectedServices.insert(label)
                }
            }
        } label: {
            Text(label)
                .font(SovaFont.body(.subheadline, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .sovaPrimaryText)
                .background(
                    isSelected ? Color.sovaPrimaryAccent : Color.sovaSurface.opacity(0.6),
                    in: .capsule
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.sovaSecondaryText.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Date Row

    private func nextDateRow(for name: String, isLast: Bool) -> some View {
        let matchingReminder = findMatchingReminder(for: name)
        let binding = Binding<Date>(
            get: { nextServiceDates[name] ?? defaultNextDate(for: name) },
            set: { nextServiceDates[name] = $0 }
        )

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption)
                    .foregroundStyle(.sovaPrimaryAccent)
                Text(name)
                    .font(SovaFont.body(.subheadline, weight: .medium))
                    .foregroundStyle(.sovaPrimaryText)

                if matchingReminder != nil {
                    Text("updates reminder")
                        .font(SovaFont.mono(.caption2))
                        .foregroundStyle(.sovaPrimaryAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.sovaPrimaryAccent.opacity(0.1), in: .capsule)
                }
            }

            HStack {
                Text("Next due")
                    .font(SovaFont.body(.footnote))
                    .foregroundStyle(.sovaPrimaryText)
                Spacer()
                DatePicker("", selection: binding, displayedComponents: .date)
                    .labelsHidden()
                    .font(SovaFont.body(.footnote))
            }

            if !isLast {
                Divider()
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Matching Reminder

    private func findMatchingReminder(for name: String) -> ItemReminder? {
        let lowered = name.lowercased()
        // Exact match first
        if let exact = item.activeReminders.first(where: { $0.name.lowercased() == lowered }) {
            return exact
        }
        return nil
    }

    // MARK: - Save

    private func logService() {
        let names = resolvedServiceNames
        guard !names.isEmpty else { return }

        // Build a single log entry for all services
        let dateString = serviceDate.formatted(date: .abbreviated, time: .omitted)
        let serviceList = names.joined(separator: ", ")
        var logEntry = "[\(dateString)] \(serviceList)"
        let trimmedLocation = serviceLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLocation.isEmpty {
            logEntry += " @ \(trimmedLocation)"
        }
        let trimmedMileage = updatedMileage.trimmingCharacters(in: .whitespacesAndNewlines)
        if item.category == .car, !trimmedMileage.isEmpty {
            logEntry += " \(trimmedMileage) \(usesMetricUnits ? "km" : "mi")"
        }
        if !serviceNotes.isEmpty {
            logEntry += " — \(serviceNotes)"
        }

        if item.notes.isEmpty {
            item.notes = logEntry
        } else {
            item.notes = logEntry + "\n" + item.notes
        }

        // Process each service
        for name in names {
            let nextDate = nextServiceDates[name] ?? defaultNextDate(for: name)
            let monthsUntilNext = Calendar.current.dateComponents([.month], from: serviceDate, to: nextDate).month ?? 6

            if let reminder = findMatchingReminder(for: name) {
                // Update existing reminder
                reminder.lastServiceDate = serviceDate
                reminder.nextDueDate = nextDate
                reminder.intervalMonths = max(monthsUntilNext, 1)
            } else {
                // Create a new reminder
                let reminder = ItemReminder(
                    name: name,
                    nextDueDate: nextDate,
                    intervalMonths: max(monthsUntilNext, 1),
                    lastServiceDate: serviceDate,
                    item: item
                )
                modelContext.insert(reminder)
            }
        }

        // Update mileage for cars
        if item.category == .car {
            let trimmedMileage = updatedMileage.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedMileage.isEmpty {
                var fields = item.customFields
                fields["mileage"] = trimmedMileage
                item.customFields = fields
            }
        }

        // Update item's top-level lastServiceDate
        item.lastServiceDate = serviceDate
        item.updatedAt = .now

        // Sync item-level nextDueDate from earliest active reminder (for list sorting)
        let allDates = (item.reminders ?? [])
            .filter { !$0.isComplete }
            .compactMap(\.nextDueDate)
        item.nextDueDate = allDates.sorted().first

        // Reschedule notifications
        NotificationManager.scheduleRemindersForItem(item)

        dismiss()
    }
}

// MARK: - Flow Layout

/// A simple wrapping horizontal layout for chips/tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

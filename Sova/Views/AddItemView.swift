import PhotosUI
import SwiftData
import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var itemToEdit: MaintenanceItem?
    var initialCategory: SovaCategory = .car

    @State private var title: String = ""
    @State private var itemDescription: String = ""
    @State private var category: SovaCategory = .car
    @State private var locationName: String = ""
    @State private var purchaseDate: Date = .now
    @State private var notes: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var coverPhotoIndex: Int?

    // Category-specific fields
    @State private var customFieldValues: [String: String] = [:]

    // Reminders
    @State private var reminderDrafts: [ReminderDraft] = []
    @State private var editingReminder: ReminderDraft?
    @State private var isAddingReminder: Bool = false

    var onDelete: (() -> Void)?

    private var isEditing: Bool { itemToEdit != nil }

    private var categoryFields: [CategoryFieldDefinition] {
        CategoryFieldDefinition.fields(for: category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $title)
                        .font(SovaFont.body(.body))
                    TextField("What are you tracking?", text: $itemDescription, axis: .vertical)
                        .font(SovaFont.body(.body))
                        .lineLimit(2...4)
                    Picker("Category", selection: $category) {
                        ForEach(SovaCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                    TextField("Location", text: $locationName)
                        .font(SovaFont.body(.body))
                }

                if !categoryFields.isEmpty {
                    categoryDetailsSection
                }

                Section("Dates") {
                    DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
                }

                remindersSection

                Section("Notes") {
                    TextField("Notes, warranty details, service reminders", text: $notes, axis: .vertical)
                        .font(SovaFont.body(.body))
                        .lineLimit(4...8)
                }

                Section {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images) {
                        Label("Add photos", systemImage: "photo.on.rectangle.angled")
                    }

                    if !photoData.isEmpty {
                        Text("Tap a photo to set it as the card icon")
                            .font(SovaFont.mono(.caption))
                            .foregroundStyle(.sovaSecondaryText)

                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                                    if let image = UIImage(data: data) {
                                        Button {
                                            withAnimation(.snappy(duration: 0.2)) {
                                                coverPhotoIndex = coverPhotoIndex == index ? nil : index
                                            }
                                        } label: {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 96, height: 96)
                                                .clipped()
                                                .clipShape(.rect(cornerRadius: 16))
                                                .overlay {
                                                    if coverPhotoIndex == index {
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(Color.sovaPrimaryAccent, lineWidth: 3)
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.title3)
                                                            .foregroundStyle(.white, Color.sovaPrimaryAccent)
                                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                            .padding(6)
                                                    }
                                                }
                                                .accessibilityLabel(coverPhotoIndex == index ? "Cover photo \(index + 1)" : "Photo \(index + 1)")
                                        }
                                    }
                                }
                            }
                        }
                        .contentMargins(.horizontal, 16)
                        .scrollIndicators(.hidden)
                    }
                } header: {
                    Text("Photos")
                } footer: {
                    if coverPhotoIndex != nil {
                        Text("Selected photo will replace the category icon on the card.")
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete item", systemImage: "trash")
                                    .font(SovaFont.body(.body, weight: .medium))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.sovaBackground)
            .navigationTitle(isEditing ? "Edit item" : "New item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(
                "Delete \"\(itemToEdit?.title ?? "")\"?",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    if let item = itemToEdit {
                        NotificationManager.cancelRemindersForItem(item)
                        modelContext.delete(item)
                    }
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This item and all its photos will be permanently removed.")
            }
            .onAppear {
                if itemToEdit == nil {
                    category = initialCategory
                }
                populateFromItem()
            }
            .onChange(of: category) { _, _ in
                // Clear custom fields when category changes (unless editing)
                if !isEditing {
                    customFieldValues = [:]
                }
            }
            .onChange(of: photoData.count) { _, newCount in
                // Reset cover if index is now out of bounds
                if let idx = coverPhotoIndex, idx >= newCount {
                    coverPhotoIndex = nil
                }
            }
            .onChange(of: selectedPhotos) { _, newValue in
                Task {
                    var loadedData: [Data] = []
                    for photo in newValue {
                        if let data = try? await photo.loadTransferable(type: Data.self),
                           let compressed = Self.compressPhoto(data) {
                            loadedData.append(compressed)
                        }
                    }
                    photoData = loadedData
                }
            }
            .sheet(isPresented: $isAddingReminder) {
                ReminderEditView(draft: ReminderDraft()) { saved in
                    reminderDrafts.append(saved)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingReminder) { draft in
                ReminderEditView(draft: draft) { saved in
                    if let index = reminderDrafts.firstIndex(where: { $0.id == saved.id }) {
                        reminderDrafts[index] = saved
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Category Details Section

    private var categoryDetailsSection: some View {
        Section(category.rawValue + " Details") {
            ForEach(categoryFields) { field in
                switch field.fieldType {
                case .text, .number:
                    TextField(field.label, text: fieldBinding(for: field.key))
                        .font(SovaFont.body(.body))
                        .keyboardType(field.fieldType == .number ? .numberPad : .default)
                case .date:
                    DatePicker(field.label, selection: dateFieldBinding(for: field.key), displayedComponents: .date)
                }
            }
        }
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        Section("Reminders") {
            if reminderDrafts.isEmpty {
                Text("No reminders yet")
                    .font(SovaFont.body(.body))
                    .foregroundStyle(.sovaSecondaryText)
            } else {
                ForEach(reminderDrafts) { draft in
                    Button {
                        editingReminder = draft
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(draft.name.isEmpty ? "Untitled" : draft.name)
                                    .font(SovaFont.body(.body, weight: .medium))
                                    .foregroundStyle(.sovaPrimaryText)
                                Text("Due: \(draft.nextDueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(SovaFont.mono(.caption))
                                    .foregroundStyle(.sovaSecondaryText)
                            }
                            Spacer()
                            Text("Every \(draft.intervalMonths)mo")
                                .font(SovaFont.mono(.caption))
                                .foregroundStyle(.sovaSecondaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.sovaSecondaryText)
                        }
                    }
                }
                .onDelete { indexSet in
                    reminderDrafts.remove(atOffsets: indexSet)
                }
            }

            Button {
                isAddingReminder = true
            } label: {
                Label("Add reminder", systemImage: "plus.circle")
                    .font(SovaFont.body(.body))
            }
        }
    }

    // MARK: - Field Bindings

    private func fieldBinding(for key: String) -> Binding<String> {
        Binding(
            get: { customFieldValues[key] ?? "" },
            set: { customFieldValues[key] = $0 }
        )
    }

    private func dateFieldBinding(for key: String) -> Binding<Date> {
        Binding(
            get: {
                if let raw = customFieldValues[key], let interval = Double(raw) {
                    return Date(timeIntervalSince1970: interval)
                }
                return .now
            },
            set: {
                customFieldValues[key] = String($0.timeIntervalSince1970)
            }
        )
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = itemToEdit {
            existing.title = trimmedTitle
            existing.itemDescription = trimmedDescription
            existing.categoryRawValue = category.rawValue
            existing.locationName = locationName.isEmpty ? nil : locationName
            existing.purchaseDate = purchaseDate
            existing.notes = trimmedNotes
            existing.updatedAt = .now

            // Custom fields
            existing.customFields = customFieldValues

            // Cover photo
            existing.coverPhotoIndex = coverPhotoIndex

            // Sync reminders
            syncReminders(for: existing)

            // Replace photos
            if let oldPhotos = existing.photos {
                for photo in oldPhotos {
                    modelContext.delete(photo)
                }
            }
            existing.photos = photoData.map { ItemPhoto(data: $0, item: existing) }

            // Schedule notifications for updated reminders
            NotificationManager.scheduleRemindersForItem(existing)
        } else {
            let item = MaintenanceItem(
                title: trimmedTitle,
                itemDescription: trimmedDescription,
                categoryRawValue: category.rawValue,
                locationName: locationName.isEmpty ? nil : locationName,
                purchaseDate: purchaseDate,
                notes: trimmedNotes,
                updatedAt: .now
            )

            // Custom fields
            item.customFields = customFieldValues

            // Cover photo
            item.coverPhotoIndex = coverPhotoIndex

            item.photos = photoData.map { ItemPhoto(data: $0, item: item) }
            modelContext.insert(item)

            // Create reminders
            for draft in reminderDrafts {
                let reminder = ItemReminder(
                    name: draft.name,
                    nextDueDate: draft.nextDueDate,
                    intervalMonths: draft.intervalMonths,
                    lastServiceDate: draft.lastServiceDate,
                    item: item
                )
                modelContext.insert(reminder)
            }

            // Sync nextDueDate for widget compatibility
            syncNextDueDate(for: item)

            // Schedule notifications for new reminders
            NotificationManager.scheduleRemindersForItem(item)
        }
        dismiss()
    }

    private func syncReminders(for item: MaintenanceItem) {
        // Delete removed reminders
        let existingReminders = item.reminders ?? []
        let draftExistingIDs = Set(reminderDrafts.compactMap { $0.existingReminder?.persistentModelID })
        for reminder in existingReminders {
            if !draftExistingIDs.contains(reminder.persistentModelID) {
                modelContext.delete(reminder)
            }
        }

        // Update existing and create new
        for draft in reminderDrafts {
            if let existing = draft.existingReminder {
                existing.name = draft.name
                existing.nextDueDate = draft.nextDueDate
                existing.intervalMonths = draft.intervalMonths
                existing.lastServiceDate = draft.lastServiceDate
                existing.isComplete = draft.isComplete
            } else {
                let reminder = ItemReminder(
                    name: draft.name,
                    nextDueDate: draft.nextDueDate,
                    intervalMonths: draft.intervalMonths,
                    lastServiceDate: draft.lastServiceDate,
                    item: item
                )
                modelContext.insert(reminder)
            }
        }

        syncNextDueDate(for: item)
    }

    private func syncNextDueDate(for item: MaintenanceItem) {
        // Keep nextDueDate in sync with earliest reminder for widget/sorting compat
        let dates = reminderDrafts.map(\.nextDueDate)
        item.nextDueDate = dates.sorted().first
        item.lastServiceDate = nil
        item.serviceIntervalMonths = nil
    }

    // MARK: - Populate

    private func populateFromItem() {
        guard let item = itemToEdit else { return }
        title = item.title
        itemDescription = item.itemDescription
        category = item.category
        locationName = item.locationName ?? ""
        purchaseDate = item.purchaseDate ?? .now
        notes = item.notes
        photoData = item.photoData
        coverPhotoIndex = item.coverPhotoIndex
        customFieldValues = item.customFields
        reminderDrafts = (item.reminders ?? []).map { ReminderDraft(from: $0) }
    }

    // MARK: - Photo Compression

    /// Compresses a photo to JPEG at 0.8 quality, capping the longest edge at 2048px.
    /// Keeps enough detail for receipt text to remain readable.
    private static func compressPhoto(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }

        let maxDimension: CGFloat = 2048
        let size = image.size
        let scale: CGFloat

        if max(size.width, size.height) > maxDimension {
            scale = maxDimension / max(size.width, size.height)
        } else {
            scale = 1.0
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.8)
    }
}

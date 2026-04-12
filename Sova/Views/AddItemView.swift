import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import VisionKit

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var itemToEdit: MaintenanceItem?
    var initialCategory: SovaCategory = .car

    @State private var title: String = ""
    @State private var itemDescription: String = ""
    @State private var category: SovaCategory = .car
    @State private var purchaseDate: Date = .now
    @State private var hasPurchaseDate: Bool = false
    @State private var notes: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var showDiscardConfirmation: Bool = false
    @State private var showCameraDeniedAlert: Bool = false
    @State private var activeFullScreen: FullScreenType?

    private enum FullScreenType: String, Identifiable {
        case camera
        case documentScanner
        var id: String { rawValue }
    }
    @State private var coverPhotoIndex: Int?

    // Category-specific fields
    @State private var customFieldValues: [String: String] = [:]

    // Reminders
    @State private var reminderDrafts: [ReminderDraft] = []
    @State private var editingReminder: ReminderDraft?
    @State private var isAddingReminder: Bool = false

    var onDelete: (() -> Void)?

    private var isEditing: Bool { itemToEdit != nil }

    @AppStorage("usesMetricUnits") private var usesMetricUnits: Bool = false

    private var categoryFields: [CategoryFieldDefinition] {
        CategoryFieldDefinition.fields(for: category, usesMetricUnits: usesMetricUnits)
    }

    /// Categories that auto-generate their title from custom fields
    private var categoryAutoGeneratesTitle: Bool {
        category == .car
    }

    /// Auto-generated title built from category-specific fields
    private var generatedTitle: String {
        switch category {
        case .car:
            let year = customFieldValues["year"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let make = customFieldValues["make"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let model = customFieldValues["model"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return [year, make, model].filter { !$0.isEmpty }.joined(separator: " ")
        default:
            return ""
        }
    }

    /// The effective title used for saving — either user-entered or auto-generated
    private var effectiveTitle: String {
        categoryAutoGeneratesTitle ? generatedTitle : title
    }

    /// Whether any fields have been filled in (for discard confirmation)
    private var hasUnsavedChanges: Bool {
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if !photoData.isEmpty { return true }
        if !reminderDrafts.isEmpty { return true }
        if customFieldValues.values.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !categoryAutoGeneratesTitle {
                        TextField("Item name", text: $title)
                            .font(SovaFont.body(.body))
                    }
                    Picker("Category", selection: $category) {
                        ForEach(SovaCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                }

                if !categoryFields.isEmpty {
                    categoryDetailsSection
                }

                Section("Dates") {
                    Toggle("Purchase date", isOn: $hasPurchaseDate.animation())
                    if hasPurchaseDate {
                        DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
                    }
                }

                remindersSection

                Section("Notes") {
                    TextField("Notes, warranty details, service reminders", text: $notes, axis: .vertical)
                        .font(SovaFont.body(.body))
                        .lineLimit(4...8)
                }

                photosSection

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
                        if !isEditing && hasUnsavedChanges {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(effectiveTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            .alert(
                "Discard changes?",
                isPresented: $showDiscardConfirmation
            ) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .interactiveDismissDisabled(!isEditing && hasUnsavedChanges)
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
            .fullScreenCover(item: $activeFullScreen) { type in
                switch type {
                case .camera:
                    CameraPickerView { image in
                        if let compressed = Self.compressPhoto(image.jpegData(compressionQuality: 1.0) ?? Data()) {
                            photoData.append(compressed)
                        }
                    }
                    .ignoresSafeArea()
                case .documentScanner:
                    DocumentScannerView { images in
                        let remaining = 6 - photoData.count
                        for image in images.prefix(remaining) {
                            if let compressed = Self.compressPhoto(image.jpegData(compressionQuality: 1.0) ?? Data()) {
                                photoData.append(compressed)
                            }
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .alert("Camera Access Required", isPresented: $showCameraDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow camera access in Settings to take photos.")
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

    // MARK: - Photos Section

    private var photosSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images) {
                Label("Choose from library", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                requestCameraAccess()
            } label: {
                Label("Take photo", systemImage: "camera")
            }
            .disabled(photoData.count >= 6)

            Button {
                activeFullScreen = .documentScanner
            } label: {
                Label("Scan document", systemImage: "doc.viewfinder")
            }
            .disabled(photoData.count >= 6 || !VNDocumentCameraViewController.isSupported)

            if !photoData.isEmpty {
                Text("Tap a photo to set it as the card icon")
                    .font(SovaFont.mono(.caption))
                    .foregroundStyle(.sovaSecondaryText)

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                            if let image = UIImage(data: data) {
                                Button {
                                    withAnimation(SovaAccessibility.animation(.snappy(duration: 0.2))) {
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
        let trimmedTitle = effectiveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = itemToEdit {
            existing.title = trimmedTitle
            existing.itemDescription = trimmedDescription
            existing.categoryRawValue = category.rawValue
            existing.purchaseDate = hasPurchaseDate ? purchaseDate : nil
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
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
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
        if let date = item.purchaseDate {
            purchaseDate = date
            hasPurchaseDate = true
        }
        notes = item.notes
        photoData = item.photoData
        coverPhotoIndex = item.coverPhotoIndex
        customFieldValues = item.customFields
        reminderDrafts = (item.reminders ?? []).map { ReminderDraft(from: $0) }
    }

    // MARK: - Camera Access

    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            activeFullScreen = .camera
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        activeFullScreen = .camera
                    }
                }
            }
        case .denied, .restricted:
            showCameraDeniedAlert = true
        @unknown default:
            showCameraDeniedAlert = true
        }
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

// MARK: - Camera Picker

private struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let dismiss: DismissAction
        let onCapture: (UIImage) -> Void

        init(dismiss: DismissAction, onCapture: @escaping (UIImage) -> Void) {
            self.dismiss = dismiss
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Document Scanner

private struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onScan: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onScan: onScan)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let dismiss: DismissAction
        let onScan: ([UIImage]) -> Void

        init(dismiss: DismissAction, onScan: @escaping ([UIImage]) -> Void) {
            self.dismiss = dismiss
            self.onScan = onScan
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onScan(images)
            dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            dismiss()
        }
    }
}

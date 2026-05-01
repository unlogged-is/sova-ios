import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import VisionKit

struct ItemDetailView: View {
    let item: MaintenanceItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingEditSheet: Bool = false
    @State private var isPresentingServiceSheet: Bool = false
    @State private var selectedPhotoIndex: Int?
    @AppStorage("usesMetricUnits") private var usesMetricUnits: Bool = false

    // Photo adding
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var activeFullScreen: PhotoFullScreenType?
    @State private var showCameraDeniedAlert: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showPhotoPicker: Bool = false
    private var store: StoreManager { .shared }

    private enum PhotoFullScreenType: String, Identifiable {
        case camera
        case documentScanner
        case viewer
        var id: String { rawValue }
    }

    private var categoryFields: [CategoryFieldDefinition] {
        CategoryFieldDefinition.fields(for: item.category, usesMetricUnits: usesMetricUnits)
    }

    private var filledCategoryFields: [(label: String, value: String)] {
        let fields = item.customFields
        return categoryFields.compactMap { def in
            guard let val = fields[def.key], !val.isEmpty else { return nil }
            if def.fieldType == .date, let interval = Double(val) {
                let date = Date(timeIntervalSince1970: interval)
                return (def.label, date.formatted(date: .abbreviated, time: .omitted))
            }
            return (def.label, val)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard

                if item.category == .home && !formattedAddress.isEmpty {
                    addressCard
                }

                photoSection

                if !filledCategoryFields.isEmpty {
                    categoryDetailsCard
                }

                if item.category == .home && !roomsData.isEmpty {
                    roomsCard
                }

                detailGrid

                if let reminders = item.reminders, !reminders.isEmpty {
                    remindersCard(reminders: reminders)
                }

                notesCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(.sovaBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if item.category != .receipt && item.category != .warranty {
                floatingServiceButton
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditSheet) {
            AddItemView(itemToEdit: item) {
                dismiss()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $isPresentingServiceSheet) {
            LogServiceView(item: item)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .fullScreenCover(item: $activeFullScreen) { type in
            switch type {
            case .camera:
                CameraPickerView { image in
                    addPhoto(from: image)
                }
                .ignoresSafeArea()
            case .documentScanner:
                DocumentScannerView { images in
                    for image in images {
                        addPhoto(from: image)
                    }
                }
                .ignoresSafeArea()
            case .viewer:
                if let index = selectedPhotoIndex {
                    PhotoViewerView(photos: item.photoData, initialIndex: index)
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newValue in
            Task {
                for photo in newValue {
                    if let data = try? await photo.loadTransferable(type: Data.self),
                       let compressed = AddItemView.compressPhoto(data) {
                        let photoObj = ItemPhoto(data: compressed, item: item)
                        modelContext.insert(photoObj)
                    }
                }
                selectedPhotos = []
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(item.displayCategoryName, systemImage: item.displayCategorySymbol)
                    .font(SovaFont.mono(.caption, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(statusColor.opacity(0.14), in: .capsule)

                Spacer()

                Label(item.status.title, systemImage: item.status.symbolName)
                    .font(SovaFont.body(.footnote, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            if !item.itemDescription.isEmpty {
                Text(item.itemDescription)
                    .font(SovaFont.body(.body))
                    .foregroundStyle(.sovaPrimaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Next service", value: item.nextUpcomingServiceLabel)
                detailRow(title: "Last service", value: item.lastServiceDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not logged")
                if item.category != .car && item.category != .home {
                    detailRow(title: "Location", value: item.locationName ?? "Not set")
                }
            }
        }
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private var floatingServiceButton: some View {
        Button {
            isPresentingServiceSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.body.weight(.medium))
                Text("Log Service")
                    .font(SovaFont.body(.body, weight: .semibold))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.sovaPrimaryAccent, in: .capsule)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if item.category == .home {
                infoTile(title: "Rooms", value: "\(roomsData.count)")
                infoTile(title: "Total Sq Ft", value: totalSquareFootage > 0 ? "\(totalSquareFootage)" : "—")
            } else {
                infoTile(title: "Interval", value: item.serviceIntervalMonths.map { "\($0) months" } ?? "Flexible")
            }
            infoTile(title: "Purchase", value: item.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
            infoTile(title: "Created", value: item.createdAt.formatted(date: .abbreviated, time: .omitted))
            infoTile(title: "Photos", value: "\(item.photoData.count)")
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)

            Text(item.notes.isEmpty ? "No notes yet." : item.notes)
                .font(SovaFont.body(.body))
                .foregroundStyle(item.notes.isEmpty ? .sovaSecondaryText : .sovaPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)

            if !item.photoData.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(Array(item.photoData.enumerated()), id: \.offset) { index, data in
                            if let image: UIImage = UIImage(data: data) {
                                Button {
                                    selectedPhotoIndex = index
                                    activeFullScreen = .viewer
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 180, height: 150)
                                        .clipped()
                                        .clipShape(.rect(cornerRadius: 16))
                                        .accessibilityLabel("Photo \(index + 1) for \(item.title)")
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            addPhotoMenu
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private var addPhotoMenu: some View {
        Menu {
            Button {
                showPhotoPicker = true
            } label: {
                Label("Choose from library", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                requestCameraAccess()
            } label: {
                Label("Take photo", systemImage: "camera")
            }

            Button {
                if store.isPro {
                    activeFullScreen = .documentScanner
                } else {
                    showPaywall = true
                }
            } label: {
                Label(
                    store.isPro ? "Scan document" : "Scan document (Pro)",
                    systemImage: "doc.viewfinder"
                )
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                Text("Add photo")
                    .font(SovaFont.body(.subheadline, weight: .medium))
            }
            .foregroundStyle(.sovaPrimaryAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.sovaPrimaryAccent.opacity(0.12), in: .capsule)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, matching: .images)
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(SovaFont.mono(.caption2))
                .foregroundStyle(.sovaSecondaryText)
            Text(value)
                .font(SovaFont.body(.headline, weight: .semibold))
                .foregroundStyle(.sovaPrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.sovaSurface, in: .rect(cornerRadius: 22))
        .sovaCard(cornerRadius: 22)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(SovaFont.mono(.caption))
                .foregroundStyle(.sovaSecondaryText)
            Spacer()
            Text(value)
                .font(SovaFont.body(.subheadline, weight: .medium))
                .foregroundStyle(.sovaPrimaryText)
        }
    }

    private var categoryDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(item.displayCategoryName) Details")
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)

            ForEach(filledCategoryFields, id: \.label) { field in
                HStack {
                    Text(field.label)
                        .font(SovaFont.mono(.caption))
                        .foregroundStyle(.sovaSecondaryText)
                    Spacer()
                    Text(field.value)
                        .font(SovaFont.body(.subheadline, weight: .medium))
                        .foregroundStyle(.sovaPrimaryText)
                }
            }
        }
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private func remindersCard(reminders: [ItemReminder]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)

            ForEach(reminders, id: \.persistentModelID) { reminder in
                HStack(spacing: 12) {
                    Image(systemName: reminder.status.symbolName)
                        .foregroundStyle(reminderStatusColor(reminder.status))
                        .font(.body)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.name)
                            .font(SovaFont.body(.body, weight: .medium))
                            .foregroundStyle(.sovaPrimaryText)
                        Text(reminder.nextDueLabel)
                            .font(SovaFont.mono(.caption))
                            .foregroundStyle(.sovaSecondaryText)
                    }

                    Spacer()

                    if let interval = reminder.intervalMonths {
                        Text("Every \(interval)mo")
                            .font(SovaFont.mono(.caption))
                            .foregroundStyle(.sovaSecondaryText)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private func reminderStatusColor(_ status: MaintenanceStatus) -> Color {
        switch status {
        case .overdue:
            Color.sovaOverdue
        case .dueSoon:
            Color.sovaDueSoon
        case .scheduled:
            Color.sovaPrimaryAccent
        case .tracking:
            Color.sovaWarmAccent
        }
    }

    // MARK: - Home Address & Rooms

    private var formattedAddress: String {
        let fields = item.customFields
        let street = fields[HomeFieldKeys.street] ?? ""
        let city = fields[HomeFieldKeys.city] ?? ""
        let state = fields[HomeFieldKeys.state] ?? ""
        let zip = fields[HomeFieldKeys.zip] ?? ""

        var parts: [String] = []
        if !street.isEmpty { parts.append(street) }
        let cityStateZip = [city, state, zip].filter { !$0.isEmpty }.joined(separator: ", ")
        if !cityStateZip.isEmpty { parts.append(cityStateZip) }
        return parts.joined(separator: ", ")
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Address")
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)

            Text(formattedAddress)
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaPrimaryText)

            HStack {
                Button {
                    UIPasteboard.general.string = formattedAddress
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("Copy")
                            .font(SovaFont.body(.subheadline, weight: .medium))
                    }
                    .foregroundStyle(.sovaPrimaryAccent)
                }

                Spacer()

                Button {
                    let query = formattedAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "maps://?q=\(query)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("Open in Maps")
                            .font(SovaFont.body(.subheadline, weight: .medium))
                    }
                    .foregroundStyle(.sovaPrimaryAccent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    private var roomsData: [(name: String, sqft: String)] {
        let fields = item.customFields
        if let countStr = fields[HomeFieldKeys.roomCount], let count = Int(countStr), count > 0 {
            return (0..<count).compactMap { i in
                let name = fields[HomeFieldKeys.roomName(i)] ?? ""
                let sqft = fields[HomeFieldKeys.roomSqft(i)] ?? ""
                guard !name.isEmpty else { return nil }
                return (name, sqft)
            }
        }
        // Legacy fallback
        if let legacy = fields[HomeFieldKeys.legacyAreaRoom], !legacy.isEmpty {
            return [(legacy, fields[HomeFieldKeys.legacySquareFootage] ?? "")]
        }
        return []
    }

    private var totalSquareFootage: Int {
        roomsData.compactMap { Int($0.sqft) }.reduce(0, +)
    }

    private var roomsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rooms")
                    .font(SovaFont.title(.title3))
                    .foregroundStyle(.sovaPrimaryText)
                Spacer()
                if totalSquareFootage > 0 {
                    Text("\(totalSquareFootage) sq ft total")
                        .font(SovaFont.mono(.caption))
                        .foregroundStyle(.sovaSecondaryText)
                }
            }

            ForEach(Array(roomsData.enumerated()), id: \.offset) { _, room in
                HStack {
                    Text(room.name)
                        .font(SovaFont.body(.body, weight: .medium))
                        .foregroundStyle(.sovaPrimaryText)
                    Spacer()
                    if !room.sqft.isEmpty {
                        Text("\(room.sqft) sq ft")
                            .font(SovaFont.mono(.caption))
                            .foregroundStyle(.sovaSecondaryText)
                    }
                }
            }
        }
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 28))
        .sovaCard(cornerRadius: 28)
    }

    // MARK: - Photo Helpers

    private func addPhoto(from image: UIImage) {
        guard let compressed = AddItemView.compressPhoto(image.jpegData(compressionQuality: 1.0) ?? Data()) else { return }
        let photoObj = ItemPhoto(data: compressed, item: item)
        modelContext.insert(photoObj)
    }

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

    private var statusColor: Color {
        switch item.status {
        case .overdue:
            Color.sovaOverdue
        case .dueSoon:
            Color.sovaDueSoon
        case .scheduled:
            Color.sovaPrimaryAccent
        case .tracking:
            Color.sovaWarmAccent
        }
    }
}

// MARK: - Full-Screen Photo Viewer

private struct PhotoViewerView: View {
    let photos: [Data]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                    if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: .circle)
            }
            .padding(16)
        }
        .onAppear {
            currentIndex = initialIndex
        }
        .statusBarHidden()
    }
}

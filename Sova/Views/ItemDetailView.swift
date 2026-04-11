import SwiftData
import SwiftUI

struct ItemDetailView: View {
    let item: MaintenanceItem
    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingEditSheet: Bool = false
    @State private var isPresentingServiceSheet: Bool = false
    @State private var selectedPhotoIndex: Int?

    private var categoryFields: [CategoryFieldDefinition] {
        CategoryFieldDefinition.fields(for: item.category)
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

                if !item.photoData.isEmpty {
                    photoStrip
                }

                if !filledCategoryFields.isEmpty {
                    categoryDetailsCard
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
            floatingServiceButton
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
        .fullScreenCover(isPresented: Binding(
            get: { selectedPhotoIndex != nil },
            set: { if !$0 { selectedPhotoIndex = nil } }
        )) {
            if let index = selectedPhotoIndex {
                PhotoViewerView(photos: item.photoData, initialIndex: index)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label(item.category.rawValue, systemImage: item.category.symbolName)
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
                detailRow(title: "Location", value: item.locationName ?? "Not set")
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
            infoTile(title: "Interval", value: item.serviceIntervalMonths.map { "\($0) months" } ?? "Flexible")
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

    private var photoStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(item.photoData.enumerated()), id: \.offset) { index, data in
                    if let image: UIImage = UIImage(data: data) {
                        Button {
                            selectedPhotoIndex = index
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 150)
                                .clipped()
                                .clipShape(.rect(cornerRadius: 20))
                                .accessibilityLabel("Photo \(index + 1) for \(item.title)")
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
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
            Text("\(item.category.rawValue) Details")
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

import PhotosUI
import SwiftData
import SwiftUI

private enum SovaRoute: Hashable {
    case detail(PersistentIdentifier)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\MaintenanceItem.nextDueDate, order: .forward),
        SortDescriptor(\MaintenanceItem.updatedAt, order: .reverse)
    ]) private var items: [MaintenanceItem]

    @State private var path: [SovaRoute] = []
    @State private var selectedCategory: SovaCategory? = nil
    @State private var showCategoryPicker: Bool = false
    @State private var selectedNewCategory: SovaCategory? = nil
    @State private var isPresentingSettingsSheet: Bool = false
    @State private var searchText: String = ""
    @State private var itemToDelete: MaintenanceItem?
    @State private var showDeleteConfirmation: Bool = false
    @State private var activeSwipeID: PersistentIdentifier?
    @State private var isOverdueCollapsed: Bool = false
    @State private var isComingDueCollapsed: Bool = false
    @AppStorage("swipeToDeleteEnabled") private var swipeToDeleteEnabled: Bool = true
    @AppStorage("hiddenCategories") private var hiddenCategoriesRaw: String = ""

    private var hiddenCategorySet: Set<String> {
        Set(hiddenCategoriesRaw.split(separator: ",").map(String.init))
    }

    private var visibleItems: [MaintenanceItem] {
        let hidden = hiddenCategorySet
        guard !hidden.isEmpty else { return items }
        return items.filter { !hidden.contains($0.categoryRawValue) }
    }

    private var filteredItems: [MaintenanceItem] {
        guard let selectedCategory else { return visibleItems }
        return visibleItems.filter { $0.category == selectedCategory }
    }

    private var overdueItems: [MaintenanceItem] {
        filteredItems.filter { $0.status == .overdue }
            .sorted { ($0.earliestDueDate ?? .distantFuture) < ($1.earliestDueDate ?? .distantFuture) }
    }

    private var comingDueItems: [MaintenanceItem] {
        filteredItems.filter { $0.status == .dueSoon }
            .sorted { ($0.earliestDueDate ?? .distantFuture) < ($1.earliestDueDate ?? .distantFuture) }
    }

    private var recentlyUpdatedItems: [MaintenanceItem] {
        Array(visibleItems.sorted { $0.updatedAt > $1.updatedAt }.prefix(6))
    }

    private var searchFilteredItems: [MaintenanceItem] {
        guard !searchText.isEmpty else { return filteredItems }
        let query = searchText.lowercased()
        return filteredItems.filter {
            $0.title.lowercased().contains(query) ||
            $0.itemDescription.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    searchBar
                    if !items.isEmpty {
                        if searchText.isEmpty {
                            if !overdueItems.isEmpty {
                                overdueSection
                            }
                            comingDueSection
                        }
                        inventorySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, _ in
                if activeSwipeID != nil {
                    withAnimation(SovaAccessibility.animation(.snappy(duration: 0.2))) { activeSwipeID = nil }
                }
            }
            .background(.sovaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sova")
                        .font(SovaFont.appTitle(size: 32))
                        .foregroundStyle(.sovaPrimaryAccent)
                }
            }
            .navigationDestination(for: SovaRoute.self) { route in
                switch route {
                case .detail(let identifier):
                    if let item: MaintenanceItem = items.first(where: { $0.persistentModelID == identifier }) {
                        ItemDetailView(item: item)
                    } else {
                        ContentUnavailableView("Item not found", systemImage: "tray")
                    }
                }
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableStateView {
                        withAnimation(SovaAccessibility.animation(.spring(duration: 0.35, bounce: 0.2))) {
                            showCategoryPicker = true
                        }
                    }
                }
            }
            .overlay {
                if showCategoryPicker {
                    categoryPickerOverlay
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SovaBottomBar(
                    selectedCategory: $selectedCategory,
                    hiddenCategories: hiddenCategorySet,
                    isPickerOpen: showCategoryPicker,
                    onAddTapped: {
                        withAnimation(SovaAccessibility.animation(.spring(duration: 0.35, bounce: 0.2))) {
                            showCategoryPicker.toggle()
                        }
                    },
                    onSettingsTapped: { isPresentingSettingsSheet = true },
                    onDismissPicker: {
                        withAnimation(SovaAccessibility.animation(.spring(duration: 0.35, bounce: 0.2))) {
                            showCategoryPicker = false
                        }
                    }
                )
            }
            .sheet(item: $selectedNewCategory) { category in
                AddItemView(initialCategory: category)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $isPresentingSettingsSheet) {
                SettingsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onOpenURL { url in
                guard url.scheme == "sova",
                      url.host == "item",
                      let idString = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "id" })?.value
                else { return }
                // Decode base64url back to standard base64
                var base64 = idString
                    .replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                let remainder = base64.count % 4
                if remainder > 0 {
                    base64 += String(repeating: "=", count: 4 - remainder)
                }
                guard let data = Data(base64Encoded: base64),
                      let identifier = try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
                else { return }
                path = [.detail(identifier)]
            }
            .task {
                SovaWidgetStore.save(items: items)
                NotificationManager.scheduleAllReminders(items: items)
            }
            .onChange(of: items.count) { _, _ in
                SovaWidgetStore.save(items: items)
            }
            .onChange(of: path) { _, _ in
                if activeSwipeID != nil {
                    activeSwipeID = nil
                }
            }
        }
    }

    private var visibleCategories: [SovaCategory] {
        let hidden = hiddenCategorySet
        return SovaCategory.allCases.filter { !hidden.contains($0.rawValue) }
    }

    private var categoryPickerOverlay: some View {
        ZStack(alignment: .bottom) {
            // Scrim
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(SovaAccessibility.animation(.spring(duration: 0.35, bounce: 0.2))) {
                        showCategoryPicker = false
                    }
                }

            // Picker card
            VStack(spacing: 16) {
                Text("New item")
                    .font(SovaFont.title(.title3))
                    .foregroundStyle(.sovaPrimaryText)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                    ForEach(visibleCategories) { category in
                        Button {
                            withAnimation(SovaAccessibility.animation(.spring(duration: 0.35, bounce: 0.2))) {
                                showCategoryPicker = false
                            }
                            // Small delay so the picker dismisses before the sheet appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                selectedNewCategory = category
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: category.symbolName)
                                    .font(.title3)
                                    .foregroundStyle(.sovaPrimaryAccent)
                                    .frame(width: 44, height: 44)
                                    .background(Color.sovaPrimaryAccent.opacity(0.12), in: .circle)
                                Text(category.rawValue)
                                    .font(SovaFont.mono(.caption2))
                                    .foregroundStyle(.sovaPrimaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(20)
            .modifier(GlassPickerBackgroundModifier())
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.sovaSecondaryText)

            TextField("Search items...", text: $searchText)
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaPrimaryText)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.sovaSecondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.sovaSurface, in: .rect(cornerRadius: 16))
        .sovaCard(cornerRadius: 16)
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) { isOverdueCollapsed.toggle() }
            } label: {
                HStack {
                    Text("Overdue")
                        .font(SovaFont.title(.title2))
                        .foregroundStyle(.sovaPrimaryText)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.sovaSecondaryText)
                        .rotationEffect(.degrees(isOverdueCollapsed ? 0 : 90))
                    Spacer()
                    Text("\(overdueItems.count)")
                        .font(SovaFont.mono(.caption, weight: .medium))
                        .foregroundStyle(.sovaSecondaryText)
                }
            }
            .buttonStyle(.plain)

            if !isOverdueCollapsed {
                VStack(spacing: 12) {
                    ForEach(overdueItems) { item in
                        Button {
                            path.append(.detail(item.persistentModelID))
                        } label: {
                            DueItemRow(item: item, isOverdue: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var comingDueSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) { isComingDueCollapsed.toggle() }
            } label: {
                HStack {
                    Text("Coming due")
                        .font(SovaFont.title(.title2))
                        .foregroundStyle(.sovaPrimaryText)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.sovaSecondaryText)
                        .rotationEffect(.degrees(isComingDueCollapsed ? 0 : 90))
                    Spacer()
                    Text(comingDueItems.isEmpty ? "Quiet" : "\(comingDueItems.count)")
                        .font(SovaFont.mono(.caption, weight: .medium))
                        .foregroundStyle(.sovaSecondaryText)
                }
            }
            .buttonStyle(.plain)

            if !isComingDueCollapsed {
                if comingDueItems.isEmpty {
                    quietCard
                } else {
                    VStack(spacing: 12) {
                        ForEach(comingDueItems) { item in
                            Button {
                                path.append(.detail(item.persistentModelID))
                            } label: {
                                DueItemRow(item: item, isOverdue: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var inventorySection: some View {
        let displayItems = searchFilteredItems.isEmpty && searchText.isEmpty && selectedCategory == nil ? recentlyUpdatedItems : searchFilteredItems
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedCategory?.rawValue ?? "Inventory")
                    .font(SovaFont.title(.title2))
                    .foregroundStyle(.sovaPrimaryText)
                Spacer()
                Text("\(displayItems.count)")
                    .font(SovaFont.mono(.caption, weight: .medium))
                    .foregroundStyle(.sovaSecondaryText)
            }

            LazyVStack(spacing: 12) {
                ForEach(displayItems) { item in
                    if swipeToDeleteEnabled {
                        SwipeToDeleteCard(item: item, activeSwipeID: $activeSwipeID) {
                            path.append(.detail(item.persistentModelID))
                        } onDelete: {
                            itemToDelete = item
                            showDeleteConfirmation = true
                        }
                    } else {
                        Button {
                            path.append(.detail(item.persistentModelID))
                        } label: {
                            InventoryCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .alert(
            "Delete \"\(itemToDelete?.title ?? "")\"?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    modelContext.delete(item)
                    itemToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("This item and all its photos will be permanently removed.")
        }
    }

    private var quietCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing urgent")
                .font(SovaFont.title(.headline))
                .foregroundStyle(.sovaSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.sovaSurface, in: .rect(cornerRadius: 26))
        .sovaCard()
    }


}

private struct DueItemRow: View {
    let item: MaintenanceItem
    var isOverdue: Bool = false

    private var accentColor: Color {
        isOverdue ? .sovaOverdue : .sovaDueSoon
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.category.symbolName)
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(SovaFont.title(.title3))
                    .foregroundStyle(.sovaPrimaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.nextUpcomingServiceLabel)
                    .font(SovaFont.mono(.caption))
                    .foregroundStyle(.sovaSecondaryText)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.sovaSecondaryText)
        }
        .padding(16)
        .background(.sovaSurface, in: .rect(cornerRadius: 24))
        .sovaCard(cornerRadius: 24)
    }
}

private struct InventoryCard: View {
    let item: MaintenanceItem
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isLargeType: Bool {
        dynamicTypeSize >= .accessibility1
    }

    private var subtitle: String? {
        let fields = item.customFields
        switch item.category {
        case .car:
            if let plate = fields["plateNumber"], !plate.isEmpty { return plate }
        case .hvac:
            let parts = [fields["systemType"], fields["filterSize"]]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        case .appliance:
            let parts = [fields["brand"], fields["modelNumber"]]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        default:
            break
        }
        return nil
    }

    var body: some View {
        Group {
            if isLargeType {
                largeTypeLayout
            } else {
                standardLayout
            }
        }
        .padding(18)
        .background(.sovaSurface, in: .rect(cornerRadius: 26))
        .sovaCard()
    }

    private var standardLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            cardContent
            Spacer(minLength: 8)
            cardThumbnail
        }
    }

    private var largeTypeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.status.title)
                    .font(SovaFont.mono(.caption, weight: .medium))
                    .foregroundStyle(statusColor)
                Spacer()
                Image(systemName: item.category.symbolName)
                    .font(.body)
                    .foregroundStyle(statusColor)
            }
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(SovaFont.title(.title3))
                .foregroundStyle(.sovaPrimaryText)
                .lineLimit(isLargeType ? 2 : 1)

            Text(subtitle ?? " ")
                .font(SovaFont.body(.subheadline))
                .foregroundStyle(.sovaSecondaryText)
                .lineLimit(isLargeType ? 2 : 1)

            Label(item.nextUpcomingServiceLabel, systemImage: "clock")
                .font(SovaFont.mono(.caption))
                .foregroundStyle(.sovaSecondaryText)
                .lineLimit(isLargeType ? 2 : 1)

            let reminderCount = item.activeReminders.count
            if reminderCount > 0 {
                Label(
                    "\(reminderCount) reminder\(reminderCount == 1 ? "" : "s")",
                    systemImage: "bell"
                )
                .font(SovaFont.mono(.caption))
                .foregroundStyle(.sovaSecondaryText)
            }
        }
    }

    private var cardThumbnail: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(item.status.title)
                .font(SovaFont.mono(.caption, weight: .medium))
                .foregroundStyle(statusColor)
            if let data: Data = item.coverPhotoData, let image: UIImage = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: item.category.symbolName)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 72, height: 72)
                    .background(statusColor.opacity(0.12), in: .rect(cornerRadius: 18))
            }
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

private struct SwipeToDeleteCard: View {
    let item: MaintenanceItem
    @Binding var activeSwipeID: PersistentIdentifier?
    var onTap: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging: Bool = false

    private var isOpen: Bool { activeSwipeID == item.persistentModelID }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind — only visible when swiped
            if offset < 0 {
                Button {
                    onDelete()
                    withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) { close() }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 72)
                        .frame(maxHeight: .infinity)
                }
                .background(Color.red, in: .rect(cornerRadius: 26))
            }

            // Card on top
            Button(action: {
                if isOpen {
                    withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) { close() }
                } else {
                    onTap()
                }
            }) {
                InventoryCard(item: item)
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if !isDragging {
                            let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                            guard isHorizontal else { return }
                            isDragging = true
                        }

                        let base: CGFloat = isOpen ? -72 : 0
                        let newOffset = base + value.translation.width
                        offset = min(0, max(-100, newOffset))
                    }
                    .onEnded { value in
                        defer { isDragging = false }
                        guard isDragging else { return }

                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) {
                            if value.translation.width < -30 || velocity < -200 {
                                offset = -72
                                activeSwipeID = item.persistentModelID
                            } else {
                                close()
                            }
                        }
                    }
            )
        }
        .clipped()
        .onChange(of: activeSwipeID) { _, newID in
            // Close this card if another card was swiped open
            if newID != item.persistentModelID && offset < 0 {
                withAnimation(SovaAccessibility.animation(.snappy(duration: 0.25))) { offset = 0 }
            }
        }
    }

    private func close() {
        offset = 0
        if activeSwipeID == item.persistentModelID {
            activeSwipeID = nil
        }
    }
}

private struct GlassPickerBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 28))
        } else {
            content
                .background(.sovaSurface, in: .rect(cornerRadius: 28))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MaintenanceItem.self, ItemPhoto.self], inMemory: true)
}

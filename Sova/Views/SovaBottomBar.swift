import SwiftUI

struct SovaBottomBar: View {
    @Binding var selectedCategory: SovaCategory?
    var hiddenCategories: Set<String> = []
    var customCategories: [CustomCategory] = []
    var selectedCustomCategoryFilter: UUID?
    var onCustomCategorySelected: ((UUID?) -> Void)?
    var isPickerOpen: Bool = false
    var onAddTapped: () -> Void
    var onSettingsTapped: () -> Void
    var onDismissPicker: (() -> Void)? = nil

    private var visibleCategories: [SovaCategory] {
        SovaCategory.allCases.filter { $0 != .other && !hiddenCategories.contains($0.rawValue) }
    }

    private var selectedCustom: CustomCategory? {
        guard let id = selectedCustomCategoryFilter else { return nil }
        return customCategories.first { $0.id == id }
    }

    private var filterIcon: String {
        if let custom = selectedCustom { return custom.symbolName }
        return selectedCategory?.symbolName ?? "square.grid.2x2"
    }

    private var filterLabel: String {
        if let custom = selectedCustom { return custom.name }
        return selectedCategory?.rawValue ?? "All"
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    selectedCategory = nil
                    onCustomCategorySelected?(nil)
                } label: {
                    Label("All", systemImage: "square.grid.2x2")
                }

                ForEach(visibleCategories) { category in
                    Button {
                        onCustomCategorySelected?(nil)
                        selectedCategory = category
                    } label: {
                        Label(category.rawValue, systemImage: category.symbolName)
                    }
                }
                if !customCategories.isEmpty {
                    Divider()
                    ForEach(customCategories) { custom in
                        Button {
                            selectedCategory = nil
                            onCustomCategorySelected?(custom.id)
                        } label: {
                            Label(custom.name, systemImage: custom.symbolName)
                        }
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: filterIcon)
                        .font(.title3)
                    Text(filterLabel)
                        .font(SovaFont.mono(.caption2))
                }
                .foregroundStyle(.sovaPrimaryText)
                .frame(maxWidth: .infinity)
            }

            Button(action: onAddTapped) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isPickerOpen ? 45 : 0))
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonModifier())
            }
            .accessibilityLabel(isPickerOpen ? "Close" : "Add item")

            Button {
                onDismissPicker?()
                onSettingsTapped()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                    Text("Settings")
                        .font(SovaFont.mono(.caption2))
                }
                .foregroundStyle(.sovaPrimaryText)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: selectedCategory) { _, _ in
            onDismissPicker?()
        }
        .modifier(GlassBarBackgroundModifier())
        .padding(.horizontal, 40)
    }
}

private struct GlassBarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(.sovaSurface, in: .capsule)
                .shadow(color: .black.opacity(0.06), radius: 12, y: -4)
        }
    }
}

private struct GlassCircleButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(.sovaPrimaryAccent).interactive(), in: .circle)
        } else {
            content
                .foregroundStyle(.sovaBackground)
                .background(.sovaPrimaryAccent, in: .circle)
        }
    }
}

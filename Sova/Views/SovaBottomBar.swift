import SwiftUI

struct SovaBottomBar: View {
    @Binding var selectedCategory: SovaCategory?
    var hiddenCategories: Set<String> = []
    var onAddTapped: () -> Void
    var onSettingsTapped: () -> Void

    private var visibleCategories: [SovaCategory] {
        SovaCategory.allCases.filter { !hiddenCategories.contains($0.rawValue) }
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    selectedCategory = nil
                } label: {
                    Label("All", systemImage: "square.grid.2x2")
                }

                ForEach(visibleCategories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.rawValue, systemImage: category.symbolName)
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedCategory?.symbolName ?? "square.grid.2x2")
                        .font(.title3)
                    Text(selectedCategory?.rawValue ?? "All")
                        .font(SovaFont.mono(.caption2))
                }
                .foregroundStyle(.sovaPrimaryText)
                .frame(maxWidth: .infinity)
            }

            Button(action: onAddTapped) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .modifier(GlassCircleButtonModifier())
            }
            .accessibilityLabel("Add item")

            Button(action: onSettingsTapped) {
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

import SwiftData
import SwiftUI

struct CreateCustomCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var existingCategory: CustomCategory?

    @State private var name: String = ""
    @State private var selectedSymbol: String = "folder.fill"
    @State private var selectedTint: String = "accentPrimary"

    private var isEditing: Bool { existingCategory != nil }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Category name", text: $name)
                        .font(SovaFont.body(.body))
                } header: {
                    Text("Name")
                        .font(SovaFont.mono(.caption2))
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                        ForEach(CustomCategory.availableIcons, id: \.symbol) { icon in
                            Button {
                                selectedSymbol = icon.symbol
                            } label: {
                                Image(systemName: icon.symbol)
                                    .font(.title3)
                                    .foregroundStyle(
                                        selectedSymbol == icon.symbol ? tintColor : .sovaSecondaryText
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedSymbol == icon.symbol
                                            ? tintColor.opacity(0.15)
                                            : Color.sovaSecondaryText.opacity(0.08),
                                        in: .rect(cornerRadius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedSymbol == icon.symbol ? tintColor : .clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Icon")
                        .font(SovaFont.mono(.caption2))
                }

                Section {
                    HStack(spacing: 12) {
                        ForEach(CustomCategory.availableTints, id: \.key) { tint in
                            let color = tintColorFor(tint.key)
                            Button {
                                selectedTint = tint.key
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.sovaPrimaryText, lineWidth: selectedTint == tint.key ? 2.5 : 0)
                                            .padding(selectedTint == tint.key ? -3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Color")
                        .font(SovaFont.mono(.caption2))
                }

                // Preview
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: selectedSymbol)
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 44, height: 44)
                            .background(tintColor.opacity(0.12), in: .circle)
                        Text(name.isEmpty ? "Category name" : name)
                            .font(SovaFont.body(.headline, weight: .semibold))
                            .foregroundStyle(name.isEmpty ? .sovaSecondaryText : .sovaPrimaryText)
                    }
                } header: {
                    Text("Preview")
                        .font(SovaFont.mono(.caption2))
                }
            }
            .scrollContentBackground(.hidden)
            .background(.sovaBackground)
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if let existing = existingCategory {
                name = existing.name
                selectedSymbol = existing.symbolName
                selectedTint = existing.tintName
            }
        }
    }

    private var tintColor: Color {
        tintColorFor(selectedTint)
    }

    private func tintColorFor(_ key: String) -> Color {
        switch key {
        case "accentPrimary": .sovaPrimaryAccent
        case "accentWarm": .sovaWarmAccent
        case "dueSoon": .sovaDueSoon
        default: .sovaSecondaryText
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let existing = existingCategory {
            existing.name = trimmedName
            existing.symbolName = selectedSymbol
            existing.tintName = selectedTint
        } else {
            let category = CustomCategory(
                name: trimmedName,
                symbolName: selectedSymbol,
                tintName: selectedTint
            )
            modelContext.insert(category)
        }
        dismiss()
    }
}

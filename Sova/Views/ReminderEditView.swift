import SwiftUI

struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State var draft: ReminderDraft
    var onSave: (ReminderDraft) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Reminder name", text: $draft.name)
                        .font(SovaFont.body(.body))
                }

                Section("Schedule") {
                    DatePicker("Next due", selection: $draft.nextDueDate, displayedComponents: .date)
                    Stepper(value: $draft.intervalMonths, in: 1...60) {
                        Text("Every \(draft.intervalMonths) months")
                            .font(SovaFont.body(.body))
                    }
                    DatePicker("Last service", selection: lastServiceBinding, displayedComponents: .date)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.sovaBackground)
            .navigationTitle(draft.existingReminder != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var lastServiceBinding: Binding<Date> {
        Binding(
            get: { draft.lastServiceDate ?? .now },
            set: { draft.lastServiceDate = $0 }
        )
    }
}

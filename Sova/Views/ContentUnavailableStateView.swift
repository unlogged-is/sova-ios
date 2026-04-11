import SwiftUI

struct ContentUnavailableStateView: View {
    var onAddItem: () -> Void = {}

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Icon cluster
            ZStack {
                Circle()
                    .fill(Color.sovaPrimaryAccent.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "archivebox")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.sovaPrimaryAccent.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("No items yet")
                    .font(SovaFont.title(.title2))
                    .foregroundStyle(.sovaPrimaryText)

                Text("Add your car, appliance, or anything\nyou want to keep maintained.")
                    .font(SovaFont.body(.body))
                    .foregroundStyle(.sovaSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: onAddItem) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                    Text("Add your first item")
                        .font(SovaFont.body(.headline, weight: .semibold))
                }
                .foregroundStyle(.sovaBackground)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.sovaPrimaryAccent, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

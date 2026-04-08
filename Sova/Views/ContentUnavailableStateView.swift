import SwiftUI

struct ContentUnavailableStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Nothing tracked yet", systemImage: "archivebox.fill")
                .font(SovaFont.body(.title3, weight: .semibold))
        } description: {
            Text("Start with a car, HVAC, bike, appliance, or any other thing you own.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
        }
    }
}

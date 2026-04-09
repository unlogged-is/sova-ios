import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color.sovaBackground.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                notificationsPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            if let uiImage = UIImage(named: "AppIcon") ?? Bundle.main.icon {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 26))
            }

            Text("Sova")
                .font(.custom("CormorantGaramond-Italic", size: 64))
                .foregroundStyle(.sovaWarmAccent)

            Text("The things you own,\none place to care for them.")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)
                .multilineTextAlignment(.center)

            Text("Cars, appliances, electronic, warranties, and the rest of home life. Sova helps you keep track of your belongings.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            continueButton { withAnimation { currentPage = 1 } }
                .padding(.bottom, 72)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Features

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Everything in one place")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)

            VStack(alignment: .leading, spacing: 20) {
                featureRow(
                    icon: "calendar.badge.clock",
                    title: "Maintenance tracking",
                    subtitle: "Know what's due and when"
                )
                featureRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Photos & notes",
                    subtitle: "Keep receipts, warranty info, and details"
                )
                featureRow(
                    icon: "icloud.fill",
                    title: "Synced everywhere",
                    subtitle: "Your data backed up with iCloud, synced across devices"
                )
            }
            .padding(.horizontal, 8)

            Spacer()

            continueButton { withAnimation { currentPage = 2 } }
                .padding(.bottom, 72)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Notifications

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.sovaWarmAccent)

            Text("Stay on top of things")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)

            Text("Get a heads-up when maintenance is due so nothing slips through the cracks.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Maybe later")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaSecondaryText)
                }

                continueButton(title: "Enable notifications") {
                    requestNotificationPermission()
                }
            }
            .padding(.bottom, 72)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func continueButton(title: String = "Continue", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SovaFont.body(.headline, weight: .semibold))
                .foregroundStyle(.sovaBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.sovaPrimaryAccent, in: .rect(cornerRadius: 16))
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.sovaPrimaryAccent)
                .frame(width: 44, height: 44)
                .background(.sovaPrimaryAccent.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SovaFont.body(.headline, weight: .semibold))
                    .foregroundStyle(.sovaPrimaryText)
                Text(subtitle)
                    .font(SovaFont.body(.subheadline))
                    .foregroundStyle(.sovaSecondaryText)
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

private extension Bundle {
    var icon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }
}

import SwiftData
import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentPage: Int = 0

    // Car fields for onboarding
    @State private var carMake: String = ""
    @State private var carModel: String = ""
    @State private var carYear: String = ""
    @State private var carMileage: String = ""
    @AppStorage("usesMetricUnits") private var usesMetricUnits: Bool = false
    @AppStorage("sovaAppearance") private var appearance: String = SovaAppearance.system.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sovaBackground.ignoresSafeArea()

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    notificationsPage.tag(2)
                    addCarPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Spacer()

            if let uiImage = UIImage(named: "AppIcon") ?? Bundle.main.icon {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 26))
            }

            Text("Sova")
                .font(SovaFont.appTitle(size: 64))
                .foregroundStyle(.sovaWarmAccent)

            Text("The things you own,\none place to care for them.")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)
                .multilineTextAlignment(.center)

            Text("Cars, appliances, electronics and the rest of home life. Sova helps you keep track of your stuff.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            continueButton { withAnimation { currentPage = 1 } }
                .padding(.bottom, 72)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 540 : .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Features

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Everything in one place")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)

            Text("From oil changes to appliance warranties. Everything in one app.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(
                    icon: "calendar.badge.clock",
                    title: "Maintenance tracking",
                    subtitle: "Know what's due and when"
                )
                featureRow(
                    icon: "bell.badge.fill",
                    title: "Smart reminders",
                    subtitle: "Get notified before service is due"
                )
                featureRow(
                    icon: "icloud.fill",
                    title: "Synced everywhere",
                    subtitle: "Backed up and synced with iCloud"
                )
                featureRow(
                    icon: "infinity",
                    title: "Unlimited items",
                    subtitle: "Track everything you own, no limits",
                    isPro: true
                )
                featureRow(
                    icon: "doc.viewfinder",
                    title: "Document scanning",
                    subtitle: "Scan receipts, warranties & more",
                    isPro: true
                )
                featureRow(
                    icon: "folder.badge.plus",
                    title: "Custom categories",
                    subtitle: "Organize with your own categories",
                    isPro: true
                )
            }
            .padding(.horizontal, 8)

            Spacer()

            continueButton { withAnimation { currentPage = 2 } }
                .padding(.bottom, 72)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 540 : .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Notifications

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.system(size: 56))
                .foregroundStyle(.sovaPrimaryAccent)

            Text("Make it yours")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)

            Text("Choose your look and decide how you want to be reminded.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text("Appearance")
                    .font(SovaFont.mono(.caption, weight: .medium))
                    .foregroundStyle(.sovaSecondaryText)

                Picker("Appearance", selection: $appearance) {
                    ForEach(SovaAppearance.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 70)

            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.sovaPrimaryAccent)

                Text("Stay on top of things")
                    .font(SovaFont.body(.headline, weight: .semibold))
                    .foregroundStyle(.sovaPrimaryText)

                Text("Get a heads-up when maintenance is due so nothing slips through the cracks.")
                    .font(SovaFont.body(.subheadline))
                    .foregroundStyle(.sovaSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Skip notifications")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaSecondaryText)
                }

                continueButton(title: "Enable notifications") {
                    requestNotificationPermission()
                }
            }
            .padding(.bottom, 72)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 540 : .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Add Car

    private var addCarPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(.sovaPrimaryAccent)

            Text("Add your car")
                .font(SovaFont.title(.title2))
                .foregroundStyle(.sovaPrimaryText)

            Text("Start tracking maintenance for your vehicle. You can always add more items later.")
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 14) {
                onboardingField("Make", text: $carMake, placeholder: "e.g. Toyota")
                onboardingField("Model", text: $carModel, placeholder: "e.g. Camry")
                onboardingField("Year", text: $carYear, placeholder: "e.g. 2022", keyboard: .numberPad)

                VStack(alignment: .leading, spacing: 6) {
                    Text(usesMetricUnits ? "Mileage (km)" : "Mileage (mi)")
                        .font(SovaFont.mono(.caption, weight: .medium))
                        .foregroundStyle(.sovaSecondaryText)

                    HStack(spacing: 10) {
                        TextField("e.g. 45,000", text: $carMileage)
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.sovaSurface, in: .rect(cornerRadius: 12))

                        HStack(spacing: 0) {
                            unitButton("mi", isSelected: !usesMetricUnits) {
                                usesMetricUnits = false
                            }
                            unitButton("km", isSelected: usesMetricUnits) {
                                usesMetricUnits = true
                            }
                        }
                        .background(.sovaSurface, in: .rect(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(SovaFont.body(.body, weight: .semibold))
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaSecondaryText)
                }

                continueButton(title: "Add car & get started") {
                    createCarAndComplete()
                }
                .disabled(carGeneratedTitle.isEmpty)
                .opacity(carGeneratedTitle.isEmpty ? 0.5 : 1)
            }
            .padding(.bottom, 72)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 540 : .infinity)
        .padding(.horizontal, 24)
    }

    private var carGeneratedTitle: String {
        let parts = [carYear, carMake, carModel]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    private func unitButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(SovaFont.mono(.subheadline, weight: .medium))
                .foregroundStyle(isSelected ? .sovaBackground : .sovaSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? Color.sovaPrimaryAccent : .clear, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func onboardingField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SovaFont.mono(.caption, weight: .medium))
                .foregroundStyle(.sovaSecondaryText)
            TextField(placeholder, text: text)
                .font(SovaFont.body(.body))
                .foregroundStyle(.sovaPrimaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.sovaSurface, in: .rect(cornerRadius: 12))
                .keyboardType(keyboard)
        }
    }

    private func createCarAndComplete() {
        let title = carGeneratedTitle
        guard !title.isEmpty else { return }

        let car = MaintenanceItem(
            title: title,
            itemDescription: "",
            categoryRawValue: SovaCategory.car.rawValue
        )
        var fields: [String: String] = [
            "make": carMake.trimmingCharacters(in: .whitespacesAndNewlines),
            "model": carModel.trimmingCharacters(in: .whitespacesAndNewlines),
            "year": carYear.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        let trimmedMileage = carMileage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMileage.isEmpty {
            fields["mileage"] = trimmedMileage
        }
        car.customFields = fields
        modelContext.insert(car)
        try? modelContext.save()
        completeOnboarding()
    }

    // MARK: - Helpers

    private func continueButton(title: String = "Continue", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SovaFont.body(.headline, weight: .semibold))
                .foregroundStyle(.sovaBackground)
                .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                .padding(.vertical, 16)
                .background(.sovaPrimaryAccent, in: .rect(cornerRadius: 16))
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String, isPro: Bool = false) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.sovaPrimaryAccent)
                .frame(width: 44, height: 44)
                .background(.sovaPrimaryAccent.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SovaFont.body(.headline, weight: .semibold))
                        .foregroundStyle(.sovaPrimaryText)
                    if isPro {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.sovaWarmAccent)
                    }
                }
                Text(subtitle)
                    .font(SovaFont.body(.subheadline))
                    .foregroundStyle(.sovaSecondaryText)
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                withAnimation { currentPage = 3 }
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

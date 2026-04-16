import SwiftData
import SwiftUI

enum SovaAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@main
struct SovaApp: App {
    @AppStorage("sovaAppearance") private var appearance: String = SovaAppearance.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("useSystemFonts") private var useSystemFonts: Bool = false
    @AppStorage("highContrastEnabled") private var highContrastEnabled: Bool = false
    @AppStorage("reduceMotionEnabled") private var reduceMotionEnabled: Bool = false

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MaintenanceItem.self,
            ItemPhoto.self,
            ItemReminder.self,
            CustomCategory.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(SovaWidgetStore.appGroupID),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .id("\(useSystemFonts)-\(highContrastEnabled)-\(reduceMotionEnabled)")
            .tint(.sovaPrimaryAccent)
            .preferredColorScheme(SovaAppearance(rawValue: appearance)?.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}

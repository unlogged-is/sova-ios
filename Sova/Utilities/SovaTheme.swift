import SwiftUI

enum SovaTheme {
    static let background: Color = Color(hex: 0xFAF8F4)
    static let textPrimary: Color = Color(hex: 0x1C1A17)
    static let surface: Color = Color(hex: 0xF5F0E8)
    static let textSecondary: Color = Color(hex: 0x8C8478)
    static let accentPrimary: Color = Color(hex: 0x4A5C45)
    static let accentWarm: Color = Color(hex: 0xA0735A)
    static let dueSoon: Color = Color(hex: 0xC8923A)
    static let overdue: Color = Color(hex: 0xC45534)

    static let darkBackground: Color = Color(hex: 0x211D19)
    static let darkTextPrimary: Color = Color(hex: 0xF4EEE4)
    static let darkSurface: Color = Color(hex: 0x2D2722)
    static let darkTextSecondary: Color = Color(hex: 0xB5AA9B)
    static let darkAccentPrimary: Color = Color(hex: 0x7F9676)
    static let darkAccentWarm: Color = Color(hex: 0xC0937B)
    static let darkDueSoon: Color = Color(hex: 0xD6A64C)
    static let darkOverdue: Color = Color(hex: 0xD46852)

    // High-contrast light — pure white bg, visible card borders, strong text
    static let hcBackground: Color = Color(hex: 0xFFFFFF)
    static let hcTextPrimary: Color = Color(hex: 0x000000)
    static let hcSurface: Color = Color(hex: 0xFFFFFF)
    static let hcTextSecondary: Color = Color(hex: 0x3A3632)
    static let hcAccentPrimary: Color = Color(hex: 0x2E4228)
    static let hcAccentWarm: Color = Color(hex: 0x7A4E30)
    static let hcDueSoon: Color = Color(hex: 0x8C6010)
    static let hcOverdue: Color = Color(hex: 0x9A2E10)
    static let hcBorder: Color = Color(hex: 0xB5AA98)

    // High-contrast dark — pure black bg, visible card borders, bright text
    static let hcDarkBackground: Color = Color(hex: 0x000000)
    static let hcDarkTextPrimary: Color = Color(hex: 0xFFFFFF)
    static let hcDarkSurface: Color = Color(hex: 0x000000)
    static let hcDarkTextSecondary: Color = Color(hex: 0xD8CCBC)
    static let hcDarkAccentPrimary: Color = Color(hex: 0xB0D4A0)
    static let hcDarkAccentWarm: Color = Color(hex: 0xE8BFA0)
    static let hcDarkDueSoon: Color = Color(hex: 0xF5D060)
    static let hcDarkOverdue: Color = Color(hex: 0xF87868)
    static let hcDarkBorder: Color = Color(hex: 0x5A5045)
}

enum SovaAccessibility {
    static var highContrast: Bool {
        UserDefaults.standard.bool(forKey: "highContrastEnabled")
    }

    static var reduceMotion: Bool {
        UserDefaults.standard.bool(forKey: "reduceMotionEnabled")
    }

    /// Returns the appropriate animation or nil if reduce motion is on
    static func animation(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

extension ShapeStyle where Self == Color {
    static var sovaBackground: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcBackground, dark: SovaTheme.hcDarkBackground)
        }
        return Color(light: SovaTheme.background, dark: SovaTheme.darkBackground)
    }

    static var sovaSurface: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcSurface, dark: SovaTheme.hcDarkSurface)
        }
        return Color(light: SovaTheme.surface, dark: SovaTheme.darkSurface)
    }

    static var sovaPrimaryText: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcTextPrimary, dark: SovaTheme.hcDarkTextPrimary)
        }
        return Color(light: SovaTheme.textPrimary, dark: SovaTheme.darkTextPrimary)
    }

    static var sovaSecondaryText: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcTextSecondary, dark: SovaTheme.hcDarkTextSecondary)
        }
        return Color(light: SovaTheme.textSecondary, dark: SovaTheme.darkTextSecondary)
    }

    static var sovaPrimaryAccent: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcAccentPrimary, dark: SovaTheme.hcDarkAccentPrimary)
        }
        return Color(light: SovaTheme.accentPrimary, dark: SovaTheme.darkAccentPrimary)
    }

    static var sovaWarmAccent: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcAccentWarm, dark: SovaTheme.hcDarkAccentWarm)
        }
        return Color(light: SovaTheme.accentWarm, dark: SovaTheme.darkAccentWarm)
    }

    static var sovaDueSoon: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcDueSoon, dark: SovaTheme.hcDarkDueSoon)
        }
        return Color(light: SovaTheme.dueSoon, dark: SovaTheme.darkDueSoon)
    }

    static var sovaOverdue: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcOverdue, dark: SovaTheme.hcDarkOverdue)
        }
        return Color(light: SovaTheme.overdue, dark: SovaTheme.darkOverdue)
    }

    static var sovaCardBorder: Color {
        if SovaAccessibility.highContrast {
            return Color(light: SovaTheme.hcBorder, dark: SovaTheme.hcDarkBorder)
        }
        return .clear
    }
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

enum SovaFont {
    static var useSystemFonts: Bool {
        UserDefaults.standard.bool(forKey: "useSystemFonts")
    }

    static func title(_ textStyle: Font.TextStyle) -> Font {
        if useSystemFonts {
            return .system(textStyle, design: .serif)
        }
        return .custom("CormorantGaramond-Regular", size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    static func titleItalic(_ textStyle: Font.TextStyle) -> Font {
        if useSystemFonts {
            return .system(textStyle, design: .serif).italic()
        }
        return .custom("CormorantGaramond-Italic", size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    static func body(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        if useSystemFonts {
            return .system(textStyle, design: .default, weight: weight)
        }
        return .custom("Epilogue-Variable", size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    static func mono(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        if useSystemFonts {
            return .system(textStyle, design: .monospaced, weight: weight)
        }
        let name: String = weight == .medium || weight == .semibold || weight == .bold ? "DMMono-Medium" : "DMMono-Regular"
        return .custom(name, size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    /// The branded "Sova" title font — always CormorantGaramond
    static func appTitle(size: CGFloat) -> Font {
        .custom("CormorantGaramond-Italic", size: size)
    }
}

/// Adds a high-contrast border overlay to card shapes
struct SovaCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.sovaCardBorder, lineWidth: 1.5)
            )
    }
}

extension View {
    func sovaCard(cornerRadius: CGFloat = 26) -> some View {
        modifier(SovaCardStyle(cornerRadius: cornerRadius))
    }
}

extension SovaCategory {
    var tintColor: Color {
        switch tintName {
        case "accentPrimary": .sovaPrimaryAccent
        case "accentWarm": .sovaWarmAccent
        case "dueSoon": .sovaDueSoon
        default: .sovaSecondaryText
        }
    }
}

private extension Font.TextStyle {
    var defaultPointSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}

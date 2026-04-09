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
        Color(light: SovaTheme.background, dark: SovaTheme.darkBackground)
    }

    static var sovaSurface: Color {
        Color(light: SovaTheme.surface, dark: SovaTheme.darkSurface)
    }

    static var sovaPrimaryText: Color {
        Color(light: SovaTheme.textPrimary, dark: SovaTheme.darkTextPrimary)
    }

    static var sovaSecondaryText: Color {
        Color(light: SovaTheme.textSecondary, dark: SovaTheme.darkTextSecondary)
    }

    static var sovaPrimaryAccent: Color {
        Color(light: SovaTheme.accentPrimary, dark: SovaTheme.darkAccentPrimary)
    }

    static var sovaWarmAccent: Color {
        Color(light: SovaTheme.accentWarm, dark: SovaTheme.darkAccentWarm)
    }

    static var sovaDueSoon: Color {
        Color(light: SovaTheme.dueSoon, dark: SovaTheme.darkDueSoon)
    }

    static var sovaOverdue: Color {
        Color(light: SovaTheme.overdue, dark: SovaTheme.darkOverdue)
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
    static func title(_ textStyle: Font.TextStyle) -> Font {
        .custom("CormorantGaramond-Regular", size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    static func titleItalic(_ textStyle: Font.TextStyle) -> Font {
        .custom("CormorantGaramond-Italic", size: textStyle.defaultPointSize, relativeTo: textStyle)
    }

    static func body(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            return .custom("Epilogue-Variable", size: textStyle.defaultPointSize, relativeTo: textStyle)
        default:
            return .custom("Epilogue-Variable", size: textStyle.defaultPointSize, relativeTo: textStyle)
        }
    }

    static func mono(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let name: String = weight == .medium || weight == .semibold || weight == .bold ? "DMMono-Medium" : "DMMono-Regular"
        return .custom(name, size: textStyle.defaultPointSize, relativeTo: textStyle)
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

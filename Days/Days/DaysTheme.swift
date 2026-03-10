import SwiftUI

enum DaysTheme {
    enum Colors {
        static let accent = Color(red: 0.40, green: 0.86, blue: 0.88)
        static let backgroundStart = Color(red: 0.05, green: 0.08, blue: 0.14)
        static let backgroundMid = Color(red: 0.08, green: 0.11, blue: 0.19)
        static let backgroundEnd = Color(red: 0.11, green: 0.09, blue: 0.16)
        static let cardFill = Color.white.opacity(0.09)
        static let cardStroke = Color.white.opacity(0.08)
        static let cardInnerFill = Color.white.opacity(0.07)
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.78)
        static let tertiaryText = Color.white.opacity(0.65)
        static let subduedText = Color.white.opacity(0.72)
        static let shadow = Color.black.opacity(0.12)
    }

    enum Layout {
        static let screenHorizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 28
        static let bottomPadding: CGFloat = 40
        static let cardPadding: CGFloat = 28
        static let cardCornerRadius: CGFloat = 28
        static let innerCornerRadius: CGFloat = 22
        static let inputCornerRadius: CGFloat = 18
        static let cardSpacing: CGFloat = 24
        static let gridSpacing: CGFloat = 12
        static let rowSpacing: CGFloat = 12
        static let chipSpacing: CGFloat = 8
    }

    enum Typography {
        static let brand = Font.system(size: 36, weight: .bold, design: .rounded)
        static let hero = Font.system(size: 34, weight: .semibold, design: .serif)
        static let section = Font.title3.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.footnote.weight(.medium)
        static let chip = Font.subheadline.weight(.medium)
    }
}

import SwiftUI

enum AppTheme {
    static let brand = Color(hex: "#0A84FF")
    static let brandDark = Color(hex: "#0057D9")
    static let accent = Color(hex: "#34C7F4")
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger = Color(hex: "#EF4444")
    static let info = Color(hex: "#38BDF8")

    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedCard = Color(uiColor: .systemBackground)
    static let field = Color(uiColor: .tertiarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator).opacity(0.22)
    static let mutedText = Color(uiColor: .secondaryLabel)

    static let heroGradient = LinearGradient(
        colors: [brandDark, brand, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let canvasGradient = LinearGradient(
        colors: [
            brand.opacity(0.16),
            Color(uiColor: .systemGroupedBackground),
            Color(uiColor: .systemGroupedBackground)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 14
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 30
    }
}

struct PremiumCardModifier: ViewModifier {
    var radius: CGFloat = AppTheme.Radius.lg
    var padding: CGFloat = AppTheme.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
    }
}

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body.weight(.medium))
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, 15)
            .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

struct PrimaryCTAButtonStyle: ButtonStyle {
    var isLoading = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.heroGradient, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .shadow(color: AppTheme.brand.opacity(configuration.isPressed ? 0.16 : 0.28), radius: configuration.isPressed ? 8 : 18, x: 0, y: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: configuration.isPressed)
            .opacity(isLoading ? 0.85 : 1)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(tint.opacity(0.12), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func premiumCard(radius: CGFloat = AppTheme.Radius.lg, padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        modifier(PremiumCardModifier(radius: radius, padding: padding))
    }

    func appScreenBackground() -> some View {
        background(AppTheme.canvasGradient.ignoresSafeArea())
    }
}

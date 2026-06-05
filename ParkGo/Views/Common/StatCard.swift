import SwiftUI

enum StatCardStyle {
    case standard
    case gradient(Color, Color)
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var style: StatCardStyle = .standard

    @State private var appeared = false

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardCard
            case .gradient(let from, let to):
                gradientCard(from: from, to: to)
            }
        }
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(0.05)) {
                appeared = true
            }
        }
    }

    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func gradientCard(from: Color, to: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(
            LinearGradient(colors: [from, to], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
        )
        .shadow(color: from.opacity(0.32), radius: 14, x: 0, y: 8)
    }
}

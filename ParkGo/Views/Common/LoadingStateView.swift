import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(AppTheme.brand.opacity(0.16))
                    .frame(height: 96)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.brand)
                            .scaleEffect(1.25)
                    }

                HStack(spacing: AppTheme.Spacing.sm) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(AppTheme.separator)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 7)
                        .fill(AppTheme.separator)
                        .frame(width: 76, height: 14)
                }
                RoundedRectangle(cornerRadius: 7)
                    .fill(AppTheme.separator)
                    .frame(height: 12)
            }
            .redacted(reason: .placeholder)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.xl)
    }
}

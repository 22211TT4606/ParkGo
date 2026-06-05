import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
            }
            Text(title)
        }
            .font(.footnote.weight(.bold))
            .foregroundStyle(isSelected ? .white : AppTheme.brand)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.heroGradient : LinearGradient(colors: [AppTheme.elevatedCard, AppTheme.elevatedCard], startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .white.opacity(0.18) : AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: isSelected ? AppTheme.brand.opacity(0.20) : .black.opacity(0.04), radius: isSelected ? 10 : 6, x: 0, y: 5)
    }
}

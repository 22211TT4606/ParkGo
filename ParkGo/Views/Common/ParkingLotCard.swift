import SwiftUI

// MARK: - Parking Lot Card

struct ParkingLotCard: View {
    let lot: ParkingLot
    let distanceText: String?
    var isFeatured: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            ParkingLotHeroView(seed: lot.demoImageKey, title: lot.name, isFeatured: isFeatured)
                .frame(height: isFeatured ? 180 : 154)

            // Card Body
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Name + Price Row
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lot.name)
                            .font(.system(size: isFeatured ? 17 : 15, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text(lot.address)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.mutedText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppTheme.Spacing.sm)

                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 10))
                            Text(lot.formattedPrice)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(AppTheme.brand)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppTheme.brand.opacity(0.1), in: Capsule())

                        Text("Còn \(lot.availableSpots)/\(lot.totalSpots) chỗ")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(lot.isAvailable ? AppTheme.success : AppTheme.danger)
                    }
                }

                // Occupancy Bar
                OccupancyBar(lot: lot)

                // Tags
                ParkingTagsRow(lot: lot, distanceText: distanceText)

                // CTA row
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Xem chi tiết")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.brand.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(
                    isFeatured ? AppTheme.brand.opacity(0.25) : AppTheme.separator,
                    lineWidth: isFeatured ? 1.5 : 1
                )
        )
        .shadow(
            color: isFeatured ? AppTheme.brand.opacity(0.12) : .black.opacity(0.07),
            radius: isFeatured ? 24 : 14,
            x: 0,
            y: isFeatured ? 12 : 7
        )
    }
}

// MARK: - Occupancy Bar

private struct OccupancyBar: View {
    let lot: ParkingLot

    private var occupancyColor: Color {
        guard lot.isOpen else { return AppTheme.danger }
        let rate = lot.occupancyRate
        if rate < 0.5 { return AppTheme.success }
        if rate < 0.85 { return AppTheme.warning }
        return AppTheme.danger
    }

    private var occupancyLabel: String {
        guard lot.isOpen else { return "Đóng cửa" }
        guard lot.isAvailable else { return "Đầy chỗ" }
        let rate = lot.occupancyRate
        if rate < 0.5 { return "Đang trống" }
        if rate < 0.85 { return "Đang đông" }
        return "Gần đầy"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppTheme.field)
                        .frame(height: 5)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(occupancyColor)
                        .frame(width: max(geo.size.width * lot.occupancyRate, 0), height: 5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: lot.occupancyRate)
                }
            }
            .frame(height: 5)

            HStack {
                Text(occupancyLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(occupancyColor)
                Spacer()
                Text("\(Int(lot.occupancyRate * 100))% lấp đầy")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
    }
}

// MARK: - Tags Row

private struct ParkingTagsRow: View {
    let lot: ParkingLot
    let distanceText: String?

    var body: some View {
        HStack(spacing: 6) {
            ParkingTag(
                title: lot.isAvailable ? "Còn chỗ" : "Hết chỗ",
                systemImage: lot.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill",
                color: lot.isAvailable ? AppTheme.success : AppTheme.danger
            )
            if lot.hasEVCharging {
                ParkingTag(title: "Sạc điện", systemImage: "bolt.car.fill", color: AppTheme.brand)
            }
            if lot.isOvernight {
                ParkingTag(title: "Qua đêm", systemImage: "moon.fill", color: AppTheme.warning)
            }
            if let distanceText {
                ParkingTag(title: distanceText, systemImage: "location.fill", color: AppTheme.info)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Parking Tag

struct ParkingTag: View {
    let title: String
    var systemImage: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Hero View

struct ParkingLotHeroView: View {
    let seed: String?
    let title: String
    var isFeatured: Bool = false

    private var gradient: LinearGradient {
        switch seed {
        case "landmark-81":
            return LinearGradient(colors: [Color(hex: "#0B3954"), Color(hex: "#087E8B")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "takashimaya":
            return LinearGradient(colors: [Color(hex: "#8B4A6B"), Color(hex: "#CB997E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "thiso-sala":
            return LinearGradient(colors: [Color(hex: "#006D77"), Color(hex: "#57CC99")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "crescent-mall":
            return LinearGradient(colors: [Color(hex: "#355070"), Color(hex: "#6D597A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "tsn-domestic":
            return LinearGradient(colors: [Color(hex: "#264653"), Color(hex: "#2A9D8F")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [AppTheme.brandDark, AppTheme.brand], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(gradient)

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 160, height: 160)
                .offset(x: 80, y: -50)
                .blur(radius: 2)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 90, height: 90)
                .offset(x: -20, y: 30)

            // Glass overlay strip at bottom
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))

            // Text content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: "car.front.waves.up.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Bãi đỗ xe")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.85))

                Text(title)
                    .font(.system(size: isFeatured ? 18 : 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
    }
}

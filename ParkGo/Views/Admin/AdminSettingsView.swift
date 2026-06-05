import SwiftUI

struct AdminSettingsView: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var viewModel: AdminSettingsViewModel
    @State private var showSignOutConfirm = false
    @State private var seedSuccess = false
    @State private var syncSuccess = false

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: AdminSettingsViewModel(seedDataService: dependencies.seedDataService))
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        adminProfileCard
                        syncDataCard
                        securityCard
                        signOutCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .navigationTitle("Cài đặt")
                .navigationBarTitleDisplayMode(.large)
                .appScreenBackground()
            }

            if showSignOutConfirm {
                SignOutDialogOverlay(
                    isPresented: $showSignOutConfirm,
                    onConfirm: { appState.signOut() }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showSignOutConfirm)
    }

    // MARK: - Admin Profile Card

    private var adminProfileCard: some View {
        VStack(spacing: 0) {
            // Gradient header strip
            ZStack {
                AppTheme.heroGradient
                    .frame(height: 72)
                HStack {
                    Spacer()
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.15))
                        .padding(.trailing, AppTheme.Spacing.xl)
                }
            }

            // Profile content
            VStack(spacing: AppTheme.Spacing.sm) {
                // Avatar overlapping the gradient
                ZStack {
                    Circle()
                        .fill(AppTheme.elevatedCard)
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    Text(String(profile.fullName.prefix(1)).uppercased())
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(AppTheme.heroGradient, in: Circle())
                }
                .offset(y: -36)
                .padding(.bottom, -28)

                VStack(spacing: 4) {
                    Text(profile.fullName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 7, height: 7)
                    Text("Admin · Đang hoạt động")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(AppTheme.success.opacity(0.1), in: Capsule())
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 20, x: 0, y: 10)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
    }

    // MARK: - Demo Data Card

    private var demoDataCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SettingsSectionLabel(icon: "shippingbox.fill", title: "Dữ liệu Demo", color: AppTheme.brand)

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }

            if let infoMessage = viewModel.infoMessage {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.success)
                    Text(infoMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
            }

            Text("Tạo dữ liệu mẫu bao gồm người dùng, bãi đỗ xe và đánh giá để kiểm thử hệ thống.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await viewModel.seed()
                    if viewModel.infoMessage != nil {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { seedSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { seedSuccess = false }
                        }
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: seedSuccess ? "checkmark.circle.fill" : "shippingbox.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(viewModel.isLoading ? "Đang tạo dữ liệu..." : (seedSuccess ? "Đã tạo thành công!" : "Tạo dữ liệu mẫu"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    viewModel.isLoading
                        ? AnyShapeStyle(AppTheme.brand.opacity(0.75))
                        : AnyShapeStyle(AppTheme.heroGradient),
                    in: RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                )
                .shadow(color: AppTheme.brand.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .disabled(viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: seedSuccess)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    // MARK: - Sync Data Card

    private var syncDataCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SettingsSectionLabel(icon: "arrow.triangle.2.circlepath", title: "Cập nhật Dữ liệu Demo", color: AppTheme.brand)

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }

            if let infoMessage = viewModel.infoMessage {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: syncSuccess ? "checkmark.seal.fill" : "info.circle.fill")
                        .foregroundStyle(AppTheme.success)
                    Text(infoMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.success)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
            }

            Text("Kiểm tra và thêm bãi xe, tài khoản, review còn thiếu vào Firestore. Dữ liệu đã tồn tại sẽ được bỏ qua, không ghi đè.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            // Stats row when result is available
            if let result = viewModel.syncResult, result.totalNew > 0 {
                HStack(spacing: AppTheme.Spacing.sm) {
                    SyncStatBadge(value: result.newLots, label: "bãi xe", color: AppTheme.brand)
                    SyncStatBadge(value: result.newUsers, label: "tài khoản", color: AppTheme.info)
                    SyncStatBadge(value: result.newReviews, label: "review", color: AppTheme.warning)
                    SyncStatBadge(value: result.newFavorites, label: "yêu thích", color: AppTheme.success)
                }
            }

            Button {
                Task {
                    await viewModel.sync()
                    if viewModel.infoMessage != nil {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { syncSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { syncSuccess = false }
                        }
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.9)
                    } else {
                        Image(systemName: syncSuccess ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(viewModel.isLoading ? "Đang kiểm tra..." : (syncSuccess ? "Hoàn thành!" : "Sync dữ liệu còn thiếu"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    viewModel.isLoading
                        ? AnyShapeStyle(AppTheme.brand.opacity(0.75))
                        : AnyShapeStyle(AppTheme.heroGradient),
                    in: RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                )
                .shadow(color: AppTheme.brand.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .disabled(viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: syncSuccess)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    // MARK: - Security Card

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SettingsSectionLabel(icon: "lock.shield.fill", title: "Bảo mật", color: AppTheme.warning)

            VStack(spacing: AppTheme.Spacing.sm) {
                SecurityNoteRow(
                    icon: "person.fill",
                    text: "User thường chỉ đọc/sửa dữ liệu của chính mình.",
                    color: AppTheme.info
                )
                Divider().padding(.leading, 36)
                SecurityNoteRow(
                    icon: "crown.fill",
                    text: "Admin quản lý users, parking_lots và reviews thông qua Firebase rules.",
                    color: AppTheme.warning
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    // MARK: - Sign Out Card

    private var signOutCard: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.subheadline.weight(.semibold))
                Text("Đăng xuất")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.danger.opacity(0.5))
            }
            .foregroundStyle(AppTheme.danger)
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                    .stroke(AppTheme.danger.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: AppTheme.danger.opacity(0.07), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SettingsDestructiveButtonStyle())
    }
}

// MARK: - Supporting Components

private struct SettingsSectionLabel: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct SecurityNoteRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
                .background(color.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct SyncStatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(color.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
        .opacity(value > 0 ? 1 : 0.35)
    }
}

private struct SettingsDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Sign Out Dialog Overlay

private struct SignOutDialogOverlay: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                // Icon + text block
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.danger.opacity(0.07))
                            .frame(width: 90, height: 90)
                        Circle()
                            .fill(AppTheme.danger.opacity(0.13))
                            .frame(width: 68, height: 68)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                    }

                    VStack(spacing: 8) {
                        Text("Đăng xuất?")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        Text("Bạn sẽ cần đăng nhập lại để\ntiếp tục sử dụng ứng dụng.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)

                // Action buttons
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            isPresented = false
                        }
                    } label: {
                        Text("Huỷ")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                    }

                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(width: 1, height: 54)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            onConfirm()
                        }
                    } label: {
                        Text("Đăng xuất")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 48, x: 0, y: 24)
            .padding(.horizontal, 44)
            .scaleEffect(appeared ? 1 : 0.86)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.70)) {
                appeared = true
            }
        }
    }
}

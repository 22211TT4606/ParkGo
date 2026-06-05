import SwiftUI

struct AuthView: View {
    @StateObject var viewModel: AuthViewModel
    @AppStorage("hasSeededDemoData") private var hasSeededDemoData = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    heroHeader

                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(AuthViewModel.Mode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(5)
                    .background(AppTheme.field, in: Capsule())

                    VStack(spacing: AppTheme.Spacing.md) {
                        if viewModel.mode == .signUp {
                            TextField("Họ và tên", text: $viewModel.fullName)
                                .textContentType(.name)
                                .textFieldStyle(AppTextFieldStyle())
                            TextField("Số điện thoại", text: $viewModel.phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(AppTextFieldStyle())
                        }

                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .textFieldStyle(AppTextFieldStyle())

                        SecureField("Mật khẩu", text: $viewModel.password)
                            .textContentType(viewModel.mode == .signUp ? .newPassword : .password)
                            .textFieldStyle(AppTextFieldStyle())

                        if viewModel.mode == .signUp {
                            SecureField("Nhập lại mật khẩu", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .textFieldStyle(AppTextFieldStyle())
                        }
                    }
                    .animation(.spring(response: 0.32, dampingFraction: 0.88), value: viewModel.mode)

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let infoMessage = viewModel.infoMessage {
                        Label(infoMessage, systemImage: "checkmark.seal.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }

                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Label(viewModel.mode.rawValue, systemImage: "arrow.right.circle.fill")
                        }
                    }
                    .buttonStyle(PrimaryCTAButtonStyle(isLoading: viewModel.isLoading))
                    .disabled(viewModel.isLoading)

                    if !hasSeededDemoData {
                        demoCard
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, 46)
                .padding(.bottom, 34)
            }
            .scrollDismissesKeyboard(.interactively)
            .appScreenBackground()
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.heroGradient)
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 64, height: 64)
                .shadow(color: AppTheme.brand.opacity(0.30), radius: 18, x: 0, y: 12)

                Spacer()
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("ParkGo")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .kerning(-1.4)
                    .foregroundStyle(AppTheme.heroGradient)
                    .minimumScaleFactor(0.78)
                Text("Tìm bãi đỗ xe gần bạn, lưu vị trí, theo dõi chỗ trống và mở chỉ đường trong Apple Maps.")
                    .font(.callout)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var demoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.warning)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.warning.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo nhanh")
                        .font(.headline.weight(.bold))
                    Text("Tạo tài khoản admin/user và dữ liệu mẫu Firestore để trải nghiệm app ngay.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                Task {
                    await viewModel.seedDemoData()
                    if viewModel.infoMessage != nil {
                        withAnimation(.easeOut(duration: 0.35)) {
                            hasSeededDemoData = true
                        }
                    }
                }
            } label: {
                Label(viewModel.isLoading ? "Đang tạo..." : "Tạo dữ liệu mẫu", systemImage: "shippingbox.fill")
            }
            .buttonStyle(SecondaryPillButtonStyle(tint: AppTheme.brand))
            .disabled(viewModel.isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }
}

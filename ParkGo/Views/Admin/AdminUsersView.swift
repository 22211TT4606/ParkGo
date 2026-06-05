import SwiftUI

// MARK: - Main View

struct AdminUsersView: View {
    let dependencies: AppDependencies

    @StateObject private var viewModel: AdminUsersViewModel
    @State private var searchText = ""
    @State private var selectedRole: UserRole? = nil
    @State private var expandedUserID: String? = nil
    @State private var showCreateSheet = false
    @State private var editingUser: UserProfile? = nil

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: AdminUsersViewModel(
                authService: dependencies.authService,
                userRepository: dependencies.userRepository,
                vehicleRepository: dependencies.vehicleRepository,
                checkInRepository: dependencies.checkInRepository
            )
        )
    }

    private var filteredUsers: [UserProfile] {
        viewModel.users.filter { user in
            let matchesSearch = searchText.isEmpty
                || user.fullName.localizedCaseInsensitiveContains(searchText)
                || user.email.localizedCaseInsensitiveContains(searchText)
            let matchesRole = selectedRole == nil || user.role == selectedRole
            return matchesSearch && matchesRole
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Stats Header
                        UserStatsHeaderView(users: viewModel.users)
                            .padding(.horizontal, AppTheme.Spacing.lg)

                        // Search + Filter
                        VStack(spacing: AppTheme.Spacing.sm) {
                            UserSearchBar(text: $searchText)
                                .padding(.horizontal, AppTheme.Spacing.lg)

                            UserRoleFilterBar(selected: $selectedRole)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // Content
                        if viewModel.isLoading {
                            UserListSkeletonView()
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        } else if filteredUsers.isEmpty {
                            UserEmptyStateView(isFiltered: !searchText.isEmpty || selectedRole != nil)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        } else {
                            LazyVStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(filteredUsers) { user in
                                    UserRowCard(
                                        user: user,
                                        vehicles: viewModel.userVehicles[user.id ?? ""] ?? [],
                                        checkIns: viewModel.userCheckIns[user.id ?? ""] ?? [],
                                        isExpanded: expandedUserID == user.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                                                if expandedUserID == user.id {
                                                    expandedUserID = nil
                                                } else {
                                                    expandedUserID = user.id
                                                }
                                            }
                                        },
                                        onEdit: { editingUser = user }
                                    )
                                    .task(id: expandedUserID) {
                                        if expandedUserID == user.id {
                                            await viewModel.loadDetail(for: user)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Người dùng")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.brand)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateUserSheet(viewModel: viewModel)
            }
            .sheet(item: $editingUser) { user in
                EditUserSheet(viewModel: viewModel, user: user)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - Create User Sheet

private struct CreateUserSheet: View {
    @ObservedObject var viewModel: AdminUsersViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var showPassword = false

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Avatar preview
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.brand, AppTheme.brand.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                            Text(fullName.isEmpty ? "?" : String(fullName.prefix(1)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: AppTheme.brand.opacity(0.3), radius: 12, x: 0, y: 6)
                        .padding(.top, AppTheme.Spacing.md)

                        // Form
                        VStack(spacing: AppTheme.Spacing.sm) {
                            CreateUserField(icon: "person.fill", placeholder: "Họ và tên", text: $fullName)
                            CreateUserField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                            CreateUserField(icon: "phone.fill", placeholder: "Số điện thoại (tuỳ chọn)", text: $phoneNumber, keyboardType: .phonePad)

                            // Password field
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.brand)
                                    .frame(width: 20)
                                Group {
                                    if showPassword {
                                        TextField("Mật khẩu (tối thiểu 6 ký tự)", text: $password)
                                    } else {
                                        SecureField("Mật khẩu (tối thiểu 6 ký tự)", text: $password)
                                    }
                                }
                                .font(.system(size: 15))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppTheme.mutedText)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, 14)
                            .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )

                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Error
                        if let err = viewModel.createError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.danger)
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.danger)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // Submit button
                        Button {
                            Task { await submit() }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isCreating {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                }
                                Text(viewModel.isCreating ? "Đang tạo..." : "Tạo tài khoản")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background {
                                if isValid && !viewModel.isCreating {
                                    AppTheme.heroGradient
                                } else {
                                    Color.gray.opacity(0.4)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                            .shadow(color: isValid ? AppTheme.brand.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValid || viewModel.isCreating)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Tài khoản mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
    }

    private func submit() async {
        viewModel.createError = nil
        do {
            try await viewModel.createUser(
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
                role: .user
            )
            dismiss()
        } catch {
            viewModel.createError = error.localizedDescription
        }
    }
}

private struct CreateUserField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 14)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

// MARK: - Edit User Sheet

private struct EditUserSheet: View {
    @ObservedObject var viewModel: AdminUsersViewModel
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String
    @State private var phoneNumber: String

    init(viewModel: AdminUsersViewModel, user: UserProfile) {
        self.viewModel = viewModel
        self.user = user
        _fullName = State(initialValue: user.fullName)
        _phoneNumber = State(initialValue: user.phoneNumber)
    }

    private var hasChanges: Bool {
        fullName.trimmingCharacters(in: .whitespaces) != user.fullName
            || phoneNumber.trimmingCharacters(in: .whitespaces) != user.phoneNumber
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && hasChanges
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Avatar preview
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.brand, AppTheme.brand.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                            Text(fullName.isEmpty ? "?" : String(fullName.prefix(1)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: AppTheme.brand.opacity(0.3), radius: 12, x: 0, y: 6)
                        .padding(.top, AppTheme.Spacing.md)

                        // Email (read-only)
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.mutedText)
                                .frame(width: 20)
                            Text(user.email)
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.mutedText)
                            Spacer()
                            Text("Không thể sửa")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.mutedText.opacity(0.7))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 14)
                        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Form
                        VStack(spacing: AppTheme.Spacing.sm) {
                            CreateUserField(icon: "person.fill", placeholder: "Họ và tên", text: $fullName)
                            CreateUserField(icon: "phone.fill", placeholder: "Số điện thoại (tuỳ chọn)", text: $phoneNumber, keyboardType: .phonePad)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Error
                        if let err = viewModel.updateError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.danger)
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.danger)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // Save button
                        Button {
                            Task { await submit() }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isUpdating {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "checkmark")
                                }
                                Text(viewModel.isUpdating ? "Đang lưu..." : "Lưu thay đổi")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background {
                                if isValid && !viewModel.isUpdating {
                                    AppTheme.heroGradient
                                } else {
                                    Color.gray.opacity(0.4)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                            .shadow(color: isValid ? AppTheme.brand.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValid || viewModel.isUpdating)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Chỉnh sửa tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
    }

    private func submit() async {
        viewModel.updateError = nil
        var updated = user
        updated.fullName = fullName.trimmingCharacters(in: .whitespaces)
        updated.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
        updated.updatedAt = .now
        do {
            try await viewModel.updateUser(updated)
            dismiss()
        } catch {
            viewModel.updateError = error.localizedDescription
        }
    }
}

// MARK: - Stats Header

private struct UserStatsHeaderView: View {
    let users: [UserProfile]

    private var adminCount: Int { users.filter { $0.role == .admin }.count }
    private var userCount: Int { users.filter { $0.role == .user }.count }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            UserStatPill(
                value: "\(users.count)",
                label: "Tổng",
                color: AppTheme.brand,
                icon: "person.2.fill"
            )
            UserStatPill(
                value: "\(adminCount)",
                label: "Quản trị",
                color: AppTheme.warning,
                icon: "shield.fill"
            )
            UserStatPill(
                value: "\(userCount)",
                label: "Người dùng",
                color: AppTheme.success,
                icon: "person.fill"
            )
        }
    }
}

private struct UserStatPill: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Search Bar

private struct UserSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFocused ? AppTheme.brand : AppTheme.mutedText)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField("Tìm theo tên hoặc email...", text: $text)
                .font(.system(size: 15, weight: .regular))
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 12)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(isFocused ? AppTheme.brand.opacity(0.5) : AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: isFocused ? AppTheme.brand.opacity(0.08) : .black.opacity(0.04), radius: isFocused ? 12 : 6, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Role Filter Bar

private struct UserRoleFilterBar: View {
    @Binding var selected: UserRole?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            RoleFilterChip(title: "Tất cả", icon: "square.grid.2x2", isSelected: selected == nil) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { selected = nil }
            }
            RoleFilterChip(title: "Admin", icon: "shield.fill", isSelected: selected == .admin) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { selected = .admin }
            }
            RoleFilterChip(title: "Người dùng", icon: "person.fill", isSelected: selected == .user) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { selected = .user }
            }
            Spacer()
        }
    }
}

private struct RoleFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.mutedText)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    AppTheme.heroGradient
                } else {
                    AppTheme.elevatedCard
                }
            }
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? .clear : AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: isSelected ? AppTheme.brand.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - User Row Card

private struct UserRowCard: View {
    let user: UserProfile
    let vehicles: [Vehicle]
    let checkIns: [CheckIn]
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    @State private var isPressed = false

    private var avatarColors: [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "#667EEA"), Color(hex: "#764BA2")],
            [Color(hex: "#11998E"), Color(hex: "#38EF7D")],
            [Color(hex: "#F7971E"), Color(hex: "#FFD200")],
            [Color(hex: "#EF5350"), Color(hex: "#F48FB1")],
            [Color(hex: "#42A5F5"), Color(hex: "#26C6DA")],
            [Color(hex: "#AB47BC"), Color(hex: "#7E57C2")],
        ]
        let index = abs(user.fullName.hashValue) % palettes.count
        return palettes[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Row Header (always visible)
            Button(action: onTap) {
                HStack(spacing: AppTheme.Spacing.md) {
                    // Avatar
                    ZStack {
                        LinearGradient(
                            colors: avatarColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Text(String(user.fullName.prefix(1)).uppercased())
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .shadow(color: avatarColors[0].opacity(0.35), radius: 8, x: 0, y: 4)

                    // Name + Email
                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.fullName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(user.email)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.mutedText)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Role Badge + Chevron
                    VStack(alignment: .trailing, spacing: 6) {
                        UserRoleBadge(role: user.role)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.mutedText)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isExpanded)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // Expanded Detail
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppTheme.Spacing.md)

                UserDetailSection(
                    user: user,
                    vehicles: vehicles,
                    checkIns: checkIns,
                    onEdit: onEdit
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(isExpanded ? AppTheme.brand.opacity(0.3) : AppTheme.separator, lineWidth: 1)
        )
        .shadow(
            color: isExpanded ? AppTheme.brand.opacity(0.08) : .black.opacity(0.05),
            radius: isExpanded ? 16 : 8,
            x: 0, y: isExpanded ? 8 : 4
        )
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: isExpanded)
    }
}

// MARK: - Role Badge

private struct UserRoleBadge: View {
    let role: UserRole

    private var config: (label: String, color: Color, icon: String) {
        switch role {
        case .admin: return ("Admin", AppTheme.warning, "shield.fill")
        case .user: return ("Người dùng", AppTheme.success, "person.fill")
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: config.icon)
                .font(.system(size: 9, weight: .bold))
            Text(config.label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(config.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(config.color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(config.color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - User Detail Section

private struct UserDetailSection: View {
    let user: UserProfile
    let vehicles: [Vehicle]
    let checkIns: [CheckIn]
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Edit button
            HStack {
                Spacer()
                Button(action: onEdit) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Chỉnh sửa")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.brand)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppTheme.brand.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.brand.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Profile Info
            UserInfoGrid(user: user)

            // Vehicles
            if !vehicles.isEmpty {
                UserDetailBlock(
                    title: "Xe của họ",
                    icon: "car.fill",
                    color: AppTheme.brand
                ) {
                    VStack(spacing: 6) {
                        ForEach(vehicles) { vehicle in
                            VehicleDetailRow(vehicle: vehicle)
                        }
                    }
                }
            }

            // Check-in History
            if !checkIns.isEmpty {
                UserDetailBlock(
                    title: "Lịch sử check-in",
                    icon: "clock.fill",
                    color: AppTheme.info
                ) {
                    VStack(spacing: 6) {
                        ForEach(checkIns.prefix(5)) { item in
                            CheckInDetailRow(checkIn: item)
                        }
                    }
                }
            }

            if vehicles.isEmpty && checkIns.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(AppTheme.mutedText)
                    Text("Chưa có hoạt động nào")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .padding(.top, AppTheme.Spacing.md)
    }
}

private struct UserInfoGrid: View {
    let user: UserProfile

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.xs) {
            UserInfoCell(icon: "phone.fill", label: "Điện thoại", value: user.phoneNumber.isEmpty ? "—" : user.phoneNumber)
            UserInfoCell(icon: "calendar", label: "Ngày tham gia", value: user.createdAt.formatted(.dateTime.month(.abbreviated).year()))
        }
    }
}

private struct UserInfoCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct UserDetailBlock<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
            }
            content
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct VehicleDetailRow: View {
    let vehicle: Vehicle

    private var typeIcon: String {
        switch vehicle.type {
        case .motorcycle: return "bicycle"
        case .van: return "bus"
        default: return "car"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: typeIcon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.brand.opacity(0.8))
                .frame(width: 20)
            Text("\(vehicle.brand) \(vehicle.modelName)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(vehicle.plateNumber)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.brand)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct CheckInDetailRow: View {
    let checkIn: CheckIn

    private var statusConfig: (color: Color, icon: String) {
        switch checkIn.status {
        case .normal: return (AppTheme.success, "checkmark.circle.fill")
        case .crowded: return (AppTheme.warning, "exclamationmark.circle.fill")
        case .full: return (AppTheme.danger, "xmark.circle.fill")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusConfig.icon)
                .font(.system(size: 13))
                .foregroundStyle(statusConfig.color)
            Text(checkIn.status.rawValue.capitalized)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusConfig.color)
            Text("•")
                .foregroundStyle(AppTheme.mutedText)
            Text(checkIn.note.isEmpty ? "Không có ghi chú" : checkIn.note)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)
            Spacer()
            Text(checkIn.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)
        }
    }
}

// MARK: - Skeleton Loading

private struct UserListSkeletonView: View {
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: AppTheme.Spacing.md) {
                    Circle()
                        .fill(AppTheme.field)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.field)
                            .frame(width: 140, height: 13)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.field)
                            .frame(width: 100, height: 11)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.field)
                        .frame(width: 50, height: 20)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
                .opacity(shimmer ? 0.5 : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Empty State

private struct UserEmptyStateView: View {
    let isFiltered: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.brand.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: isFiltered ? "magnifyingglass" : "person.2.slash")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.heroGradient)
            }
            Text(isFiltered ? "Không tìm thấy kết quả" : "Chưa có người dùng")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
            Text(isFiltered ? "Thử điều chỉnh tìm kiếm hoặc bộ lọc." : "Người dùng sẽ xuất hiện ở đây sau khi tham gia.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

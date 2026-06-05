import SwiftUI

struct AdminShellView: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            AdminDashboardView(dependencies: dependencies)
                .tabItem {
                    Label("Tổng quan", systemImage: "square.grid.2x2.fill")
                }

            AdminParkingLotsView(dependencies: dependencies)
                .tabItem {
                    Label("Bãi xe", systemImage: "car.2.fill")
                }

            AdminUsersView(dependencies: dependencies)
                .tabItem {
                    Label("Người dùng", systemImage: "person.3.fill")
                }

            AdminReviewsView(dependencies: dependencies)
                .tabItem {
                    Label("Đánh giá", systemImage: "text.bubble.fill")
                }

            AdminSettingsView(profile: profile, dependencies: dependencies)
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.brandDark)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

import SwiftUI

struct UserShellView: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @ObservedObject private var coordinator: NavigationCoordinator

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        self.coordinator = dependencies.navigationCoordinator
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            HomeView(profile: profile, dependencies: dependencies)
                .tabItem { Label("Trang chủ", systemImage: "house.fill") }
                .tag(0)

            MapScreen(profile: profile, dependencies: dependencies)
                .tabItem { Label("Bản đồ", systemImage: "map.fill") }
                .tag(1)

            SearchScreen(profile: profile, dependencies: dependencies)
                .tabItem { Label("Tìm kiếm", systemImage: "magnifyingglass") }
                .tag(2)

            FavoritesScreen(profile: profile, dependencies: dependencies)
                .tabItem { Label("Yêu thích", systemImage: "heart.fill") }
                .tag(3)

            ProfileScreen(profile: profile, dependencies: dependencies)
                .tabItem { Label("Hồ sơ", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(AppTheme.brand)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

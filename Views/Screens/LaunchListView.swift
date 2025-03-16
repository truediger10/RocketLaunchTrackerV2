import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var showSearchBar: Bool = false
    @State private var showingSettings = false
    @State private var refreshInProgress = false
    
    @State private var selectedCategoryFilter: CategoryFilter = .all
    @State private var isFilterMenuExpanded: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true
    
    // MARK: - Time Sections
    enum TimeSection: String, Identifiable, CaseIterable {
        case next24Hours = "Next 24 hrs"
        case thisWeek = "This Week"
        case thisMonth = "Later this Month"
        case future = "Future Missions"
        case past = "Recent Launches"
        var id: String { rawValue }
    }
    
    // MARK: - Category Filter
    enum CategoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorite = "Favorites"
        case crewed = "Crewed"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            // Background
            Styles.spaceBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Filter menu when expanded
                if isFilterMenuExpanded {
                    categoryFilterMenu
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Search bar when toggled
                if showSearchBar {
                    SearchBarView(text: $viewModel.searchText, isExpanded: $showSearchBar)
                        .padding(.horizontal, Styles.paddingStandard)
                        .padding(.bottom, Styles.paddingSmall)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main scrollable content
                ScrollView {
                    LazyVStack(spacing: Styles.spacingLarge * 1.5) {
                        // Sections
                        ForEach(TimeSection.allCases) { section in
                            if let launchesInSection = getLaunchesForSection(section),
                               !launchesInSection.isEmpty {
                                LaunchSectionView(
                                    section: section,
                                    launches: launchesInSection,
                                    viewModel: viewModel
                                )
                                .padding(.bottom, Styles.spacingMedium)
                            }
                        }
                        
                        // Empty state
                        if viewModel.filteredLaunches.isEmpty {
                            emptyStateView
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                // Pull-to-refresh
                .refreshable {
                    refreshInProgress = true
                    await viewModel.fetchLaunches(forceRefresh: true)
                    refreshInProgress = false
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .interactiveDismissDisabled(false)
        }
        .onAppear {
            // Initial data load if needed
            Task {
                if viewModel.filteredLaunches.isEmpty {
                    await viewModel.fetchLaunches(forceRefresh: false)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                Task {
                    await viewModel.fetchLaunches(forceRefresh: false)
                }
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    // MARK: - Header
    private var headerBar: some View {
        ZStack {
            // Transparent background for styling
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .overlay(
                    Rectangle()
                        .fill(Styles.cardSurface.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
            
            HStack {
                // Left - Title Area - Now entire area is clickable
                Button {
                    withAnimation(Styles.easeInOut) {
                        isFilterMenuExpanded.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: Styles.spacingSmall) {
                        Image(systemName: "flame")
                            .foregroundColor(Styles.highlightAccent)
                            .font(.system(size: Styles.iconSizeMedium, weight: .bold))
                        
                        Text("Launches")
                            .font(Styles.headerFont)
                            .foregroundColor(Styles.textPrimary)
                        
                        Text("Beta")
                            .font(.system(size: Styles.fontTiny, weight: .bold))
                            .foregroundColor(Styles.primaryAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Styles.primaryAccent.opacity(0.22))
                            .clipShape(Capsule())
                        
                        // Chevron that changes direction
                        Image(systemName: isFilterMenuExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(Styles.textSecondary)
                            .font(.system(size: Styles.fontMedium))
                            .animation(Styles.easeInOut, value: isFilterMenuExpanded)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, Styles.paddingStandard)
                
                Spacer()
                
                HStack(spacing: Styles.spacingMedium) {
                    // Search toggle - Moved to right side
                    Button {
                        withAnimation(Styles.easeInOut) {
                            showSearchBar.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: Styles.iconSizeSmall))
                            .foregroundColor(Styles.textSecondary)
                    }
                    
                    // Settings button
                    Button {
                        showingSettings = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: Styles.iconSizeSmall))
                            .foregroundColor(Styles.textSecondary)
                    }
                }
                .padding(.trailing, Styles.paddingStandard)
            }
            .padding(.bottom, Styles.paddingSmall)
        }
    }
    
    // MARK: - Category Filter Menu
       private var categoryFilterMenu: some View {
           Menu {
               ForEach(CategoryFilter.allCases) { filter in
                   Button {
                       withAnimation(Styles.easeInOut) {
                           selectedCategoryFilter = filter
                       }
                       UIImpactFeedbackGenerator(style: .light).impactOccurred()
                   } label: {
                       HStack {
                           Text(filter.rawValue)
                           if selectedCategoryFilter == filter {
                               Image(systemName: "checkmark")
                           }
                       }
                   }
               }
               if selectedCategoryFilter == .favorite {
                   Button {
                       withAnimation(Styles.easeInOut) {
                           viewModel.toggleFavoritesFilter()
                       }
                       UIImpactFeedbackGenerator(style: .light).impactOccurred()
                   } label: {
                       Label(
                           viewModel.showFavoritesOnly ? "Show All Favorites" : "Only Show Active Favorites",
                           systemImage: viewModel.showFavoritesOnly ? "star" : "star.fill"
                       )
                   }
               }
           } label: {
               HStack {
                   Text(selectedCategoryFilter.rawValue)
                       .font(Styles.buttonFont)
                       .foregroundColor(Styles.primaryAccent)
                   Image(systemName: "chevron.down")
                       .font(.system(size: Styles.fontTiny, weight: .semibold))
                       .foregroundColor(Styles.primaryAccent)
               }
               .padding(.horizontal, Styles.paddingMedium)
               .padding(.vertical, Styles.paddingSmall)
               .background(
                   Capsule()
                       .fill(Styles.primaryAccent.opacity(0.1))
                       .overlay(
                           Capsule()
                               .stroke(Styles.primaryAccent.opacity(0.3), lineWidth: Styles.hairlineBorder)
                       )
               )
           }
           .buttonStyle(ScaleButtonStyle())
       }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Styles.spacingMedium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Styles.fontDisplay))
                .foregroundColor(Styles.textTertiary)
            
            Text("No launches found")
                .font(Styles.headerFont)
                .foregroundColor(Styles.textSecondary)
            
            Text("Try adjusting your search or filters")
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                selectedCategoryFilter = .all
                viewModel.searchText = ""
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task {
                    await viewModel.fetchLaunches(forceRefresh: true)
                }
            } label: {
                Text("Reset Filters")
                    .font(Styles.buttonFont)
                    .foregroundColor(.black)
                    .padding(.horizontal, Styles.paddingMedium)
                    .padding(.vertical, Styles.paddingSmall)
                    .background(Styles.buttonGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, Styles.paddingSmall)
        }
        .padding(Styles.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                )
        )
        .grokShadow()
        .frame(height: 300)
    }
    
    // MARK: - Helper Functions
    private func getLaunchesForSection(_ section: TimeSection) -> [Launch]? {
        let launches = filteredLaunchesByCategory()
        let now = Date()
        let calendar = Calendar.current
        
        switch section {
        case .next24Hours:
            let next24Hours = calendar.date(byAdding: .hour, value: 24, to: now)!
            return launches.filter { $0.net > now && $0.net <= next24Hours }
        case .thisWeek:
            let next24Hours = calendar.date(byAdding: .hour, value: 24, to: now)!
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!
            return launches.filter { $0.net > next24Hours && $0.net <= nextWeek }
        case .thisMonth:
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!
            let nextMonth = calendar.date(byAdding: .day, value: 30, to: now)!
            return launches.filter { $0.net > nextWeek && $0.net <= nextMonth }
        case .future:
            let nextMonth = calendar.date(byAdding: .day, value: 30, to: now)!
            return launches.filter { $0.net > nextMonth }
        case .past:
            let lastWeek = calendar.date(byAdding: .day, value: -7, to: now)!
            return launches.filter { $0.net <= now && $0.net >= lastWeek }
        }
    }
    
    private func filteredLaunchesByCategory() -> [Launch] {
        switch selectedCategoryFilter {
        case .all:
            return viewModel.filteredLaunches
        case .favorite:
            // Use FavoriteService for consistency
            return viewModel.filteredLaunches.filter { FavoriteService.shared.isFavorite(launchId: $0.id) }
        case .crewed:
            return viewModel.filteredLaunches.filter {
                let name = $0.missionName.lowercased()
                let overview = $0.missionOverview?.lowercased() ?? ""
                return name.contains("crew") || overview.contains("astronaut") || overview.contains("human")
            }
        }
    }
    
    // Helper function to provide consistent feedback
    private func showToastFeedback(_ message: String, icon: String = "checkmark.circle.fill", color: Color = Styles.statusSuccess) {
        // This could be implemented to show toast messages when filter actions are taken
        // For now, we'll use haptic feedback for consistency with other actions
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - LaunchSectionView
struct LaunchSectionView: View {
    let section: LaunchListView.TimeSection
    let launches: [Launch]
    @ObservedObject var viewModel: LaunchViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            // New section header design
            VStack(alignment: .leading, spacing: Styles.spacingTiny) {
                // Launch Window label
                Text("LAUNCH WINDOW")
                    .font(.system(size: Styles.fontTiny, weight: .medium))
                    .tracking(1.0)
                    .foregroundColor(Styles.textTertiary)
                
                // Time frame and launch count
                HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Styles.highlightAccent)
                            .font(.system(size: Styles.iconSizeSmall))
                        Text(section.rawValue)
                            .font(.system(size: Styles.fontMedium, weight: .semibold))
                            .foregroundColor(Styles.textPrimary)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        
                        Spacer()
                        
                        Text("\(launches.count) Launches")
                        .font(.system(size: Styles.fontTiny, weight: .medium))
                        .foregroundColor(Styles.primaryAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Styles.primaryAccent.opacity(0.22))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Styles.paddingStandard)
                .padding(.vertical, Styles.paddingSmall)
                .background(Styles.glassHighlight.opacity(0.1))
            
            // Always show launches (no toggling)
            LazyVStack(spacing: Styles.spacingLarge * 1.5) {
                ForEach(launches) { launch in
                    ZStack {
                        NavigationLink(destination: LaunchDetailView(launch: launch, viewModel: viewModel)) {
                            EmptyView()
                        }
                        .opacity(0) // Hide the NavigationLink but keep it functional
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))

                        
                        LaunchCard(launch: launch, viewModel: viewModel)
                            .padding(.horizontal, Styles.paddingMedium)
                            .padding(.vertical, Styles.paddingTiny)
                    }
                    .padding(.bottom, Styles.spacingSmall)
                }
            }
            .padding(.top, Styles.spacingSmall)
        }
        .padding(.bottom, Styles.spacingSmall)
    }
}

struct launchlistview_Previews: PreviewProvider {
    static var previews: some View {
        LaunchListView()
    }
}

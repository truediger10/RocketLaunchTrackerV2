import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var showSearchBar: Bool = false
    @State private var showingSettings = false
    @State private var refreshInProgress = false
    @State private var scrollOffset: CGFloat = 0
    @State private var refreshAngle: Double = 0
    @State private var isFilterMenuExpanded: Bool = false
    @State private var selectedCategoryFilter: CategoryFilter = .all
    
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
                
                ZStack(alignment: .top) {
                    // Main content container
                    VStack(spacing: 0) {
                        // Search bar when toggled
                        if showSearchBar {
                            SearchBarView(text: $viewModel.searchText, isExpanded: $showSearchBar)
                                .padding(.horizontal, Styles.paddingStandard)
                                .padding(.bottom, Styles.paddingSmall)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Main scrollable content
                        ScrollView {
                            ScrollViewReader { scrollReader in
                                // Content offset tracking view - invisible
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self,
                                                   value: geometry.frame(in: .named("scrollView")).minY)
                                }
                                .frame(height: 0)
                                
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
                                    if viewModel.filteredLaunches.isEmpty && !refreshInProgress {
                                        emptyStateView
                                            .frame(maxWidth: .infinity)
                                            .padding(.top, 100)
                                    }
                                    
                                    Spacer(minLength: 100)
                                }
                            }
                        }
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                            scrollOffset = offset < 0 ? abs(offset) : 0
                        }
                        // Pull-to-refresh with animation
                        .refreshable {
                            // Start animation
                            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                refreshAngle = 360
                            }
                            
                            refreshInProgress = true
                            await viewModel.fetchLaunches(forceRefresh: true)
                            refreshInProgress = false
                            
                            // Stop animation
                            refreshAngle = 0
                        }
                    }
                    .blur(radius: isFilterMenuExpanded ? 3 : 0)
                    .animation(.easeOut(duration: 0.2), value: isFilterMenuExpanded)
                    .allowsHitTesting(!isFilterMenuExpanded)
                    
                    // Overlay and filter menu when expanded
                    if isFilterMenuExpanded {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isFilterMenuExpanded = false
                                }
                            }
                            .transition(.opacity)
                        
                        categoryFilterMenu
                            .padding(.top, Styles.paddingMedium)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                            .zIndex(10)
                    }
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
    
    // MARK: - Header Bar
    private var headerBar: some View {
        ZStack {
            // Dynamic background based on scroll offset
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(scrollOffset > 20 ? 0.5 : 0.8),
                            Color.black.opacity(scrollOffset > 20 ? 0.3 : 0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .overlay(
                    Rectangle()
                        .fill(Styles.cardSurface.opacity(scrollOffset > 20 ? 0.05 : 0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
            
            HStack {
                // Left side button - Search icon replacing hamburger menu
                Button {
                    withAnimation(Styles.spring) {
                        showSearchBar.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: Styles.iconSizeSmall))
                        .foregroundColor(showSearchBar ? Styles.primaryAccent : Styles.textSecondary)
                }
                .padding(.leading, Styles.paddingStandard)
                
                Spacer()
                
                // Center title with filter toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFilterMenuExpanded.toggle()
                        if isFilterMenuExpanded {
                            // Close search if opening filter
                            showSearchBar = false
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: Styles.spacingSmall) {
                        Text("Launches")
                            .font(Styles.headerFont)
                            .foregroundColor(Styles.textPrimary)
                            .opacity(scrollOffset > 50 ? 0.8 : 1.0) // Slight fade on scroll
                        
                        Text("Beta")
                            .font(.system(size: Styles.fontTiny, weight: .bold))
                            .foregroundColor(Styles.primaryAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Styles.primaryAccent.opacity(0.22))
                            .clipShape(Capsule())
                        
                        // Enhanced animation for chevron
                        Image(systemName: "chevron.down")
                            .foregroundColor(Styles.textSecondary)
                            .font(.system(size: Styles.fontSmall, weight: .medium))
                            .rotationEffect(Angle(degrees: isFilterMenuExpanded ? 180 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFilterMenuExpanded)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Right side button - settings
                Button {
                    showingSettings = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: Styles.iconSizeSmall))
                        .foregroundColor(Styles.textSecondary)
                }
                .padding(.trailing, Styles.paddingStandard)
            }
            .padding(.bottom, Styles.paddingSmall)
        }
        .animation(.easeOut(duration: 0.2), value: scrollOffset)
    }
    
    // MARK: - Category Filter Menu
    private var categoryFilterMenu: some View {
        VStack(spacing: Styles.spacingSmall) {
            // Custom dropdown content
            VStack(spacing: 0) {
                ForEach(CategoryFilter.allCases) { filter in
                    Button {
                        withAnimation(Styles.easeInOut) {
                            selectedCategoryFilter = filter
                            // Close the menu after selection
                            isFilterMenuExpanded = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                                .font(Styles.bodyFont)
                                .foregroundColor(Styles.textPrimary)
                            
                            Spacer()
                            
                            if selectedCategoryFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Styles.primaryAccent)
                            }
                        }
                        .padding(.horizontal, Styles.paddingMedium)
                        .padding(.vertical, Styles.paddingSmall)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if filter != CategoryFilter.allCases.last! {
                        Divider()
                            .background(Styles.glassHighlight.opacity(0.2))
                            .padding(.horizontal, Styles.paddingMedium)
                    }
                }
                
                // Additional favorites option if applicable
                if selectedCategoryFilter == .favorite {
                    Divider()
                        .background(Styles.glassHighlight.opacity(0.2))
                        .padding(.horizontal, Styles.paddingMedium)
                    
                    Button {
                        withAnimation(Styles.easeInOut) {
                            viewModel.toggleFavoritesFilter()
                            // Don't close the menu so user can see the change
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Label(
                                viewModel.showFavoritesOnly ? "Show All Favorites" : "Only Show Active Favorites",
                                systemImage: viewModel.showFavoritesOnly ? "star" : "star.fill"
                            )
                            .foregroundColor(Styles.textPrimary)
                            .font(Styles.bodyFont)
                            
                            Spacer()
                        }
                        .padding(.horizontal, Styles.paddingMedium)
                        .padding(.vertical, Styles.paddingSmall)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .stroke(Styles.glassHighlight.opacity(0.2), lineWidth: Styles.hairlineBorder)
                    )
            )
            .padding(.horizontal, Styles.paddingStandard)
        }
    }
    
    // MARK: - Loading View
    private var launchesLoadingView: some View {
        VStack(spacing: Styles.spacingLarge) {
            // Section header placeholder
            RoundedRectangle(cornerRadius: Styles.cornerRadiusSmall)
                .fill(Styles.cardSurface.opacity(0.7))
                .frame(height: 50)
                .shimmer()
                .padding(.horizontal, Styles.paddingStandard)
            
            // Launch card placeholders
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .fill(Styles.cardSurface.opacity(0.7))
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .stroke(Styles.glassHighlight.opacity(0.2), lineWidth: Styles.hairlineBorder)
                    )
                    .shimmer()
                    .padding(.horizontal, Styles.paddingStandard)
            }
        }
        .padding(.top, Styles.paddingLarge)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Styles.spacingMedium) {
            // Main image - now with animation when refresh in progress
            Image(systemName: refreshInProgress ? "arrow.triangle.2.circlepath" : "magnifyingglass")
                .font(.system(size: Styles.fontDisplay))
                .foregroundColor(Styles.textTertiary)
                .rotationEffect(Angle(degrees: refreshInProgress ? refreshAngle : 0))
            
            Text("No launches found")
                .font(Styles.headerFont)
                .foregroundColor(Styles.textSecondary)
            
            Text("Try adjusting your search or filters")
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: Styles.spacingSmall) {
                // Primary action - Reset filters
                Button {
                    selectedCategoryFilter = .all
                    viewModel.searchText = ""
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task {
                        await viewModel.fetchLaunches(forceRefresh: true)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Reset Filters")
                    }
                    .font(Styles.buttonFont)
                    .foregroundColor(.black)
                    .padding(.horizontal, Styles.paddingMedium)
                    .padding(.vertical, Styles.paddingSmall)
                    .background(Styles.buttonGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Secondary action - Refresh data
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task {
                        await viewModel.fetchLaunches(forceRefresh: true)
                    }
                } label: {
                    Text("Refresh Data")
                        .font(Styles.buttonFont)
                        .foregroundColor(Styles.textSecondary)
                        .padding(.horizontal, Styles.paddingMedium)
                        .padding(.vertical, Styles.paddingSmall)
                }
                .buttonStyle(ScaleButtonStyle())
            }
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
    @State private var selectedLaunchId: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            // Enhanced section header design
            VStack(alignment: .leading, spacing: Styles.spacingTiny) {
                // Launch Window label
                Text("LAUNCH WINDOW")
                    .font(.system(size: Styles.fontTiny, weight: .medium))
                    .tracking(1.0)
                    .foregroundColor(Styles.textTertiary)
                
                // Time frame and launch count with visual indicators
                HStack {
                    // Time icon with enhanced visual based on section type
                    ZStack {
                        Image(systemName: section == .next24Hours ? "clock.fill" : "clock")
                            .foregroundColor(section == .next24Hours ? Styles.statusWarning : Styles.highlightAccent)
                            .font(.system(size: Styles.iconSizeSmall))
                        
                        // Pulse animation for imminent launches
                        if section == .next24Hours {
                            Circle()
                                .stroke(Styles.statusWarning.opacity(0.5), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                                .scaleEffect(selectedLaunchId != nil ? 1.2 : 1.0)
                                .opacity(selectedLaunchId != nil ? 0 : 1)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true),
                                    value: UUID() // Force continuous animation
                                )
                        }
                    }
                    
                    // Section title with appropriate styling
                    Text(section.rawValue)
                        .font(.system(size: Styles.fontMedium, weight: .semibold))
                        .foregroundColor(section == .next24Hours ? Styles.statusWarning : Styles.textPrimary)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    // Visual indicator for imminent launches
                    if section == .next24Hours {
                        Circle()
                            .fill(Styles.statusWarning)
                            .frame(width: 6, height: 6)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                    
                    // Enhanced launch count badge
                    Text("\(launches.count) Launches")
                        .font(.system(size: Styles.fontTiny, weight: .medium))
                        .foregroundColor(section == .next24Hours ? Styles.statusWarning : Styles.primaryAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    section == .next24Hours ?
                                        Styles.statusWarning.opacity(0.22) :
                                        Styles.primaryAccent.opacity(0.22)
                                )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Styles.paddingStandard)
            .padding(.vertical, Styles.paddingSmall)
            .background(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusSmall)
                    .fill(Styles.glassHighlight.opacity(section == .next24Hours ? 0.15 : 0.1))
            )
            
            // Launch cards with interaction feedback
            LazyVStack(spacing: Styles.spacingLarge * 1.5) {
                ForEach(launches) { launch in
                    ZStack {
                        // Keep the NavigationLink
                        NavigationLink(destination: LaunchDetailView(launch: launch, viewModel: viewModel)) {
                            EmptyView()
                        }
                        .opacity(0) // Hide the NavigationLink but keep it functional
                        
                        // Enhanced launch card with feedback
                        LaunchCard(launch: launch, viewModel: viewModel)
                            .padding(.horizontal, Styles.paddingMedium)
                            .padding(.vertical, Styles.paddingTiny)
                            // Add interaction feedback
                            .scaleEffect(selectedLaunchId == launch.id ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedLaunchId)
                            // Handle taps explicitly for feedback
                            .onTapGesture {
                                // Store ID for animation
                                selectedLaunchId = launch.id
                                
                                // Haptic feedback
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                
                                // Reset after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    selectedLaunchId = nil
                                }
                            }
                    }
                    .padding(.bottom, Styles.spacingSmall)
                }
            }
            .padding(.top, Styles.spacingSmall)
        }
        .padding(.bottom, Styles.spacingSmall)
    }
}

// MARK: - Shimmer Effect for Loading
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0),
                            .init(color: Color.white.opacity(0.3), location: 0.3),
                            .init(color: Color.white.opacity(0.6), location: 0.5),
                            .init(color: Color.white.opacity(0.3), location: 0.7),
                            .init(color: Color.clear, location: 1)
                        ]),
                        startPoint: UnitPoint(x: -1 + phase, y: 0.5),
                        endPoint: UnitPoint(x: 2 + phase, y: 0.5)
                    )
                    .blendMode(.overlay)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.phase = 1
                }
            }
    }
}

// MARK: - ScrollView Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct launchlistview_Previews: PreviewProvider {
    static var previews: some View {
        LaunchListView()
    }
}

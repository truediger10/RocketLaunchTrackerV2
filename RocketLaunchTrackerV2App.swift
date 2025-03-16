import SwiftUI

@main
struct RocketLaunchTrackerV2App: App {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var isLoading = true
    @State private var loadingStage = LoadingStage.fetching
    
    enum LoadingStage: String {
        case fetching = "Fetching launch data..."
        case enriching = "Enriching launch data with AI..."
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    // Show rocket loading with the current stage
                    RocketLoadingView(loadingStage: $loadingStage)
                        .transition(.opacity)
                } else {
                    NavigationStack {
                        LaunchListView()
                    }
                    .transition(.opacity)
                }
            }
            .environmentObject(viewModel)
            .preferredColorScheme(.dark)
            .task {
                await loadData()
                // After loading, fade out loading screen
                withAnimation(.easeInOut(duration: 0.8)) {
                    isLoading = false
                }
            }
        }
    }
    
    func loadData() async {
        // Stage 1: Fetching
        loadingStage = .fetching
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Perform the actual data fetch
        await viewModel.fetchLaunches(forceRefresh: false)
        
        // Stage 2: Enriching
        loadingStage = .enriching
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
}
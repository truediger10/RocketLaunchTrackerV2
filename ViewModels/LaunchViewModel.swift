import SwiftUI
import UserNotifications
import Combine
import Foundation
import os

@MainActor
class LaunchViewModel: ObservableObject {
    @Published var launches: [Launch] = []
    @Published var searchText = ""
    @Published var showFavoritesOnly = false
    @Published var isInitialLoading = true
    @Published var loadingError: String? = nil
    
    private let favoritesKey = "FavoriteLaunches"
    private let enrichedLaunchesKey = "EnrichedLaunches"
    private var hasFetched = false
    private var enrichmentTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "LaunchViewModel")

    init() {
        Task { [weak self] in
            guard let self = self else { return }
            if let cachedLaunches = self.loadEnrichedLaunches(), cachedLaunches.count >= 50 {
                let updatedLaunches = cachedLaunches.map { launch -> Launch in
                    var updatedLaunch = launch
                    updatedLaunch.notificationsEnabled = false
                    return updatedLaunch
                }
                
                self.launches = updatedLaunches
                Self.logger.info("Loaded \(self.launches.count) cached launches")
                self.isInitialLoading = false
                self.hasFetched = true
                self.removeExpiredLaunches()
            }
        }
    }
    
    deinit {
        enrichmentTask?.cancel()
        prefetchTask?.cancel()
    }
    
    func fetchLaunches(forceRefresh: Bool = false, ensureMinimum: Int = 50) async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            Self.logger.info("Running in SwiftUI preview mode, skipping fetchLaunches")
            self.launches = []
            self.isInitialLoading = false
            return
        }
        #endif
        
        let cachedLaunches = loadEnrichedLaunches() ?? []
        if cachedLaunches.count < ensureMinimum {
            Self.logger.info("Insufficient cached launches (\(cachedLaunches.count)), proceeding with API fetch.")
        } else if !forceRefresh && hasFetched {
            Self.logger.info("Fetch skipped (already fetched and no force refresh)")
            return
        }

        loadingError = nil
        hasFetched = true
        
        enrichmentTask?.cancel()
        prefetchTask?.cancel()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        do {
            Self.logger.info("Fetching launches...")
            var rawLaunches = try await APIManager.shared.fetchLaunches()
            
            while rawLaunches.count < ensureMinimum {
                let additionalLaunches = try await APIManager.shared.fetchLaunches()
                rawLaunches.append(contentsOf: additionalLaunches)
                rawLaunches = Array(Set(rawLaunches)).prefix(ensureMinimum).map { $0 }
            }
            
            Self.logger.info("\(rawLaunches.count) launches fetched successfully.")
            
            var enrichedMap = [String: Launch]()
            if let cachedLaunches = loadEnrichedLaunches(), cachedLaunches.count >= ensureMinimum {
                enrichedMap = Dictionary(uniqueKeysWithValues: cachedLaunches.map { ($0.id, $0) })
                Self.logger.info("Loaded \(cachedLaunches.count) cached enriched launches")
            } else {
                Self.logger.info("No cached enriched launches found")
            }
            
            for rawLaunch in rawLaunches {
                if let alreadyEnriched = enrichedMap[rawLaunch.id] {
                    var updatedLaunch = alreadyEnriched.withUpdatedImage(alreadyEnriched.image ?? rawLaunch.image)
                    updatedLaunch.notificationsEnabled = false
                    enrichedMap[rawLaunch.id] = updatedLaunch
                } else {
                    var launchToStore = rawLaunch
                    if launchToStore.missionOverview == nil || (launchToStore.insights?.isEmpty ?? true) {
                        launchToStore = launchToStore.withDefaultEnrichment()
                    }
                    enrichedMap[rawLaunch.id] = launchToStore
                }
            }
            
            let sortedLaunches = Array(enrichedMap.values).sorted { $0.net < $1.net }
            launches = sortedLaunches
            
            removeExpiredLaunches()
            
            enrichmentTask = Task {
                await enrichLaunchesAsync(enrichedMap: enrichedMap)
            }
            
            applyFavorites()
            saveEnrichedLaunches()
            
            prefetchTask = Task {
                await prefetchImages()
            }
            
            isInitialLoading = false
            hasFetched = rawLaunches.count >= ensureMinimum
            
            Task {
                await CacheManager.shared.cleanupDiskCache()
            }
            Self.logger.info("fetchLaunches completed with \(self.launches.count) total launches in memory.")
        } catch is CancellationError {
            Self.logger.warning("Launch fetch cancelled")
        } catch {
            Self.logger.error("Launch fetch failed: \(error.localizedDescription)")
            loadingError = "Unable to load launches. Please check your connection."
            isInitialLoading = false
        }
    }
    
    /// Background bulk enrichment of multiple launches - happens after initial data load
    /// This method processes multiple launches in batches to add AI-generated content
    private func enrichLaunchesAsync(enrichedMap: [String: Launch]) async {
        // FLOW: 1. Identify unenriched launches → 2. Process in batches → 3. Save after each batch
        
        // Step 1: Find launches needing enrichment (missing overview or insights)
        let launchesToEnrich = self.launches.filter {
            $0.missionOverview == nil && ($0.insights?.isEmpty ?? true)
        }
        
        Self.logger.info("🔍 BULK ENRICHMENT: Found \(launchesToEnrich.count) launches requiring enrichment")
        
        if !launchesToEnrich.isEmpty {
            Self.logger.info("🚀 BULK ENRICHMENT: Starting batch processing of \(launchesToEnrich.count) launches")
            
            // Step 2: Process in batches to avoid overwhelming the API
            let batchSize = 5 // Process 5 launches at a time
            let totalBatches = (launchesToEnrich.count + batchSize - 1) / batchSize
            
            for i in stride(from: 0, to: launchesToEnrich.count, by: batchSize) {
                // Check for cancellation between batches
                if Task.isCancelled {
                    Self.logger.warning("❌ BULK ENRICHMENT: Process canceled by task cancellation")
                    return
                }
                
                // Calculate the current batch
                let upperBound = min(i + batchSize, launchesToEnrich.count)
                let batch = Array(launchesToEnrich[i..<upperBound])
                let currentBatch = (i/batchSize) + 1
                
                Self.logger.info("📦 BULK ENRICHMENT: Processing batch \(currentBatch)/\(totalBatches) with \(batch.count) launches")
                
                // Request enrichment for the entire batch at once from GrokService
                let startTime = Date()
                let enriched = await GrokService.shared.enrichLaunches(batch)
                let duration = Date().timeIntervalSince(startTime)
                
                Self.logger.info("⏱️ BULK ENRICHMENT: Batch \(currentBatch) completed in \(String(format: "%.2f", duration))s")
                
                // Update our data with the enriched content
                var updatedCount = 0
                for enrichedLaunch in enriched {
                    if let index = self.launches.firstIndex(where: { $0.id == enrichedLaunch.id }) {
                        // Track whether enrichment data was actually received
                        let receivedOverview = enrichedLaunch.missionOverview != nil
                        let receivedInsights = enrichedLaunch.insights != nil && !(enrichedLaunch.insights!.isEmpty)
                        
                        // Apply the enriched data to our model
                        self.launches[index].missionOverview = enrichedLaunch.missionOverview
                        self.launches[index].insights = enrichedLaunch.insights
                        
                        if receivedOverview || receivedInsights {
                            updatedCount += 1
                            Self.logger.info("✅ BULK ENRICHMENT: Updated \(enrichedLaunch.id) - got overview: \(receivedOverview), insights: \(receivedInsights ? "\(enrichedLaunch.insights?.count ?? 0) items" : "none")")
                        } else {
                            Self.logger.warning("⚠️ BULK ENRICHMENT: Launch \(enrichedLaunch.id) received no enrichment data")
                        }
                    }
                }
                
                // Step 3: Save after each batch to preserve progress
                saveEnrichedLaunches()
                Self.logger.info("💾 BULK ENRICHMENT: Saved batch \(currentBatch) results - updated \(updatedCount)/\(batch.count) launches")
                
                // Add delay between batches to avoid rate limiting
                if upperBound < launchesToEnrich.count {
                    Self.logger.info("⏳ BULK ENRICHMENT: Pausing 500ms before next batch")
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
            Self.logger.info("✅ BULK ENRICHMENT: Completed all batches - processed \(launchesToEnrich.count) launches")
        } else {
            Self.logger.info("✅ BULK ENRICHMENT: No launches need enrichment - all data is complete")
        }
    }
    
    private func prefetchImages() async {
        let launchesToPrefetch = launches
            .filter { $0.net > Date() && $0.net < Date().addingTimeInterval(7 * 24 * 60 * 60) }
            .prefix(5)
        
        for launch in launchesToPrefetch {
            if Task.isCancelled {
                return
            }
            if let imageUrl = launch.image {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageUrl)
                    await CacheManager.shared.cacheImage(data, for: launch.id)
                } catch {
                    Self.logger.error("Image prefetch failed for \(launch.id): \(error.localizedDescription)")
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func removeExpiredLaunches() {
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60)
        // Use a consistent comparison approach for Date objects
        let oldLaunches = self.launches.filter { $0.net.timeIntervalSince1970 < cutoffDate.timeIntervalSince1970 }
        
        if !oldLaunches.isEmpty {
            Self.logger.info("Removing \(oldLaunches.count) expired launches")
            self.launches.removeAll { $0.net.timeIntervalSince1970 < cutoffDate.timeIntervalSince1970 }
            self.saveEnrichedLaunches()
        }
    }
    
    func toggleFavorite(launch: Launch) {
        if let index = self.launches.firstIndex(where: { $0.id == launch.id }) {
            self.launches[index].isFavorite.toggle()
            self.saveFavorites()
        }
    }
    
    func toggleNotifications(for launch: Launch) {
        if let index = self.launches.firstIndex(where: { $0.id == launch.id }) {
            let newStatus = !self.launches[index].notificationsEnabled
            
            if newStatus {
                NotificationManager.shared.requestNotificationAuthorization { [weak self] granted, error in
                    guard let self = self else { return }
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if granted {
                            if let idx = self.launches.firstIndex(where: { $0.id == launch.id }) {
                                self.launches[idx].notificationsEnabled = true
                                NotificationManager.shared.scheduleNotification(for: self.launches[idx])
                                self.saveEnrichedLaunches()
                            }
                        } else {
                            Self.logger.warning("Notification permission denied")
                        }
                    }
                }
            } else {
                self.launches[index].notificationsEnabled = false
                NotificationManager.shared.cancelNotification(for: self.launches[index].id)
                self.saveEnrichedLaunches()
            }
        }
    }
    
    func toggleFavoritesFilter() {
        withAnimation {
            showFavoritesOnly.toggle()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Ensures a specific launch has enrichment data - called when viewing launch details
    /// This is a key method in the enrichment data flow that's triggered when a user views a launch detail
    func ensureLaunchEnriched(launchId: String) async {
        Self.logger.info("🔍 ENRICHMENT FLOW: Starting specific enrichment for launch \(launchId)")
        
        // First validate the launch exists in our data
        guard let index = launches.firstIndex(where: { $0.id == launchId }) else {
            Self.logger.error("❌ ENRICHMENT FLOW: Launch \(launchId) not found in launches array - cannot enrich")
            return
        }
        
        // Check if launch already has complete enrichment data
        let hasOverview = launches[index].missionOverview != nil
        let hasInsights = launches[index].insights != nil && !(launches[index].insights?.isEmpty ?? true)
        
        // Check if current enrichment is fallback data by looking for the pattern in fallback enrichment
        let hasFallbackData = isFallbackEnrichment(launch: launches[index])
        
        Self.logger.info("🔍 ENRICHMENT FLOW: Launch \(launchId) enrichment status - has overview: \(hasOverview), has insights: \(hasInsights), is fallback: \(hasFallbackData)")
        
        // Skip only if fully enriched AND not fallback data
        if hasOverview && hasInsights && !hasFallbackData {
            Self.logger.info("✅ ENRICHMENT FLOW: Launch \(launchId) already enriched with \(self.launches[index].insights?.count ?? 0) insights - skipping")
            return
        }
        
        if hasFallbackData {
            Self.logger.info("🔄 ENRICHMENT FLOW: Launch \(launchId) has fallback data - proceeding with API enrichment")
        }
        
        Self.logger.info("🌐 ENRICHMENT FLOW: Requesting explicit enrichment for launch \(launchId) - will call GrokService")
        
        do {
            // Call the GrokService for real enrichment - this will make API call if possible
            let startTime = Date()
            let enrichedLaunch = try await GrokService.shared.enrichLaunch(self.launches[index])
            let duration = Date().timeIntervalSince(startTime)
            
            Self.logger.info("⏱️ ENRICHMENT FLOW: Enrichment request took \(String(format: "%.2f", duration))s")
            
            // Update the launch data with enrichment results
            if let updatedIndex = self.launches.firstIndex(where: { $0.id == launchId }) {
                Self.logger.info("✅ ENRICHMENT FLOW: Updating launch \(launchId) with enrichment data")
                
                // Before/after logging for overview
                let hadOverviewBefore = self.launches[updatedIndex].missionOverview != nil
                self.launches[updatedIndex].missionOverview = enrichedLaunch.missionOverview
                let overviewLength = enrichedLaunch.missionOverview?.count ?? 0
                
                // Before/after logging for insights
                let insightsCountBefore = self.launches[updatedIndex].insights?.count ?? 0
                self.launches[updatedIndex].insights = enrichedLaunch.insights
                let insightsCountAfter = enrichedLaunch.insights?.count ?? 0
                
                Self.logger.info("📊 ENRICHMENT FLOW: Detail view enrichment results for \(launchId):")
                Self.logger.info("   - Overview: \(hadOverviewBefore ? "Updated" : "Added new") (\(overviewLength) chars)")
                Self.logger.info("   - Insights: \(insightsCountBefore) → \(insightsCountAfter)")
                
                // Log a sample insight for verification
                if let insights = enrichedLaunch.insights, !insights.isEmpty {
                    Self.logger.info("📌 ENRICHMENT FLOW: Sample insight: \(insights.first ?? "none")")
                }
                
                // Persist the enriched data
                saveEnrichedLaunches()
                Self.logger.info("💾 ENRICHMENT FLOW: Saved enriched data to persistent storage")
            }
        } catch {
            // Handle enrichment failure by applying fallback data
            Self.logger.error("❌ ENRICHMENT FLOW: Failed to enrich launch: \(error.localizedDescription)")
            
            if let updatedIndex = self.launches.firstIndex(where: { $0.id == launchId }) {
                Self.logger.info("🔄 ENRICHMENT FLOW: Applying fallback enrichment for \(launchId)")
                
                // Generate fallback content
                let fallbackEnrichment = Enrichment.createFallbackEnrichment(for: launches[updatedIndex])
                self.launches[updatedIndex].missionOverview = fallbackEnrichment.missionOverview
                self.launches[updatedIndex].insights = fallbackEnrichment.insights
                
                Self.logger.info("📊 ENRICHMENT FLOW: Applied fallback enrichment:")
                Self.logger.info("   - Overview: \(fallbackEnrichment.missionOverview?.count ?? 0) chars")
                Self.logger.info("   - Insights: \(fallbackEnrichment.insights?.count ?? 0) items")
                
                // Persist the fallback data
                saveEnrichedLaunches()
                Self.logger.info("💾 ENRICHMENT FLOW: Saved fallback data to persistent storage")
            }
        }
    }
    
    /// Apply fallback enrichment data to a specific launch - used when viewing details
    /// This method is called directly from the LaunchDetailView when it appears
    /// It ensures we always have at least placeholder content rather than empty sections
    func enrichSpecificLaunch(id: String) {
        // DATA FLOW: Called by LaunchDetailView.onAppear → Check if enrichment needed → Apply fallback data immediately
        
        // Only apply fallback if launch exists and is missing enrichment data
        guard let index = launches.firstIndex(where: { $0.id == id }),
              launches[index].missionOverview == nil || launches[index].insights == nil || (launches[index].insights?.isEmpty ?? true) else {
            // Already has enrichment data, no action needed
            Self.logger.info("📌 FALLBACK: Launch \(id) already has enrichment data - no fallback needed")
            return
        }
        
        Self.logger.info("🔍 FALLBACK: Creating immediate fallback enrichment for launch \(id)")
        
        // Generate fallback content - this uses the launch data to create plausible content
        let fallback = Enrichment.createFallbackEnrichment(for: launches[index])
        
        Self.logger.info("📊 FALLBACK: Created content - overview: \(fallback.missionOverview?.count ?? 0) chars, insights: \(fallback.insights?.count ?? 0) items")
        
        // Apply fallback data on main thread immediately
        DispatchQueue.main.async {
            if let idx = self.launches.firstIndex(where: { $0.id == id }) {
                Self.logger.info("✅ FALLBACK: Applying fallback content to launch \(id)")
                
                // Apply the fallback data
                self.launches[idx].missionOverview = fallback.missionOverview
                self.launches[idx].insights = fallback.insights
                
                // Persist the changes
                self.saveEnrichedLaunches()
                Self.logger.info("💾 FALLBACK: Saved enriched launches with fallback data")
            }
        }
        
        // Note: The UI will initially show this fallback data, but ensureLaunchEnriched() may later
        // be called to get real API-generated content and update the UI
    }
    
    func handleMemoryWarning() {
        Self.logger.warning("Handling memory warning in LaunchViewModel")
        LaunchImageLoader.shared.clearCache()
        enrichmentTask?.cancel()
        prefetchTask?.cancel()
    }
    
    // MARK: - Private Helper Methods
    
    /// Detects if a launch has fallback enrichment data rather than API-generated content
    private func isFallbackEnrichment(launch: Launch) -> Bool {
        // Check for patterns unique to fallback data
        if let overview = launch.missionOverview {
            // Fallback overview contains this pattern: "A [rocket] rocket launching from [location]"
            if overview.contains("A \(launch.rocketName) rocket launching from \(launch.location)") {
                return true
            }
        }
        
        if let insights = launch.insights, insights.count > 0 {
            // Fallback insights contain this pattern: "This mission uses the [rocket]"
            if insights.contains(where: { $0.contains("This mission uses the \(launch.rocketName)") }) {
                return true
            }
        }
        
        return false
    }
    
    private func loadEnrichedLaunches() -> [Launch]? {
        guard let data = UserDefaults.standard.data(forKey: enrichedLaunchesKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([Launch].self, from: data)
        } catch {
            Self.logger.error("Failed to load cached launches: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveEnrichedLaunches() {
        if let encoded = try? JSONEncoder().encode(launches) {
            UserDefaults.standard.set(encoded, forKey: enrichedLaunchesKey)
        }
    }
    
    private func applyFavorites() {
        // Apply favorites from FavoriteService to our launch models
        for launchId in FavoriteService.shared.getAllFavorites() {
            if let index = self.launches.firstIndex(where: { $0.id == launchId }) {
                self.launches[index].isFavorite = true
            }
        }
    }
    
    private func saveFavorites() {
        // Get all favorite launch ids
        let favorites = self.launches.filter { $0.isFavorite }.map { $0.id }
        
        // Use the FavoriteService to save them
        for launchId in favorites {
            FavoriteService.shared.addFavorite(Launch(
                id: launchId,
                name: "",
                net: Date(),
                provider: "",
                location: "",
                padLatitude: nil,
                padLongitude: nil,
                missionOverview: nil,
                insights: nil,
                image: nil,
                rocketName: "",
                isFavorite: true,
                notificationsEnabled: false,
                status: nil,
                missionName: "",
                probability: nil,
                url: nil,
                slug: nil,
                launchDesignator: nil,
                windowStart: nil,
                windowEnd: nil,
                webcastLive: nil,
                mission: nil
            ))
        }
    }
    
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            (showFavoritesOnly ? launch.isFavorite : true) &&
            (searchText.isEmpty
             || launch.name.lowercased().contains(searchText.lowercased())
             || launch.provider.lowercased().contains(searchText.lowercased())
             || launch.missionName.lowercased().contains(searchText.lowercased()))
        }
    }
}

extension Launch {
    func withUpdatedImage(_ image: URL?) -> Launch {
        var copy = self
        copy.image = image
        return copy
    }
    
    func withDefaultEnrichment() -> Launch {
        var copy = self
        copy.missionOverview = nil
        copy.insights = nil
        copy.isFavorite = false
        copy.notificationsEnabled = false
        return copy
    }
}
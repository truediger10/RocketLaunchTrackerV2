import Foundation
import os

/// Service for enriching launch data using AI-powered text generation (placeholder / example service).
actor GrokService {
    // MARK: - Properties
    
    static let shared = GrokService()
    
    // Example endpoint
    private let endpoint = "https://api.x.ai/v1/chat/completions"
    private let defaultModel = "grok-2-latest"
    
    // In-memory cache for enriched data
    private let cache = NSCache<NSString, CacheEntry>()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 180
        return URLSession(configuration: configuration)
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    private let maxConcurrentRequests = 3
    private let enrichedCacheKey = "EnrichedLaunches"
    
    // OSLog
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "GrokService")
    
    // MARK: - Cache Entry
    final class CacheEntry {
        let launch: Launch
        let timestamp: Date
        
        init(launch: Launch, timestamp: Date) {
            self.launch = launch
            self.timestamp = timestamp
        }
    }
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024
    }
    
    // MARK: - Public Methods
    
    func enrichLaunch(_ launch: Launch) async throws -> Launch {
        // FLOW: 1. Check cache → 2. Check API key → 3. Try API → 4. Fallback if needed
        
        // Step 1: Check if we have a valid cached entry for this launch
        let cacheKey = "\(launch.id)" as NSString
        if let entry = cache.object(forKey: cacheKey),
           Date().timeIntervalSince(entry.timestamp) < Config.shared.cacheExpirationInterval {
            Self.logger.info("🔍 ENRICHMENT FLOW: Cache hit for launch \(launch.id)")
            return entry.launch
        }
        
        // Step 2: Verify API key availability - if missing, use fallback content
        Self.logger.info("🔑 ENRICHMENT FLOW: Checking API key for \(launch.id), key exists: \(Config.shared.grokAPIKey != nil), empty: \(Config.shared.grokAPIKey?.isEmpty ?? true)")
        guard Config.shared.grokAPIKey != nil, !Config.shared.grokAPIKey!.isEmpty else {
            Self.logger.warning("⚠️ ENRICHMENT FLOW: No API key available, using fallback enrichment data for \(launch.id)")
            let fallbackEnrichment = Enrichment.createFallbackEnrichment(for: launch)
            
            var updated = launch
            updated.missionOverview = fallbackEnrichment.missionOverview
            updated.insights = fallbackEnrichment.insights
            
            Self.logger.info("📝 ENRICHMENT FLOW: Fallback enrichment created with \(fallbackEnrichment.insights?.count ?? 0) insights")
            if let insights = fallbackEnrichment.insights {
                for (i, insight) in insights.enumerated() {
                    Self.logger.info("📌 Insight \(i): \(insight)")
                }
            }
            
            // Cache the fallback enrichment to avoid regenerating it
            let entry = CacheEntry(launch: updated, timestamp: Date())
            cache.setObject(entry, forKey: cacheKey)
            
            return updated
        }
        
        // Step 3: Try to fetch real enrichment data from the API
        do {
            Self.logger.info("🌐 ENRICHMENT FLOW: Fetching from API for \(launch.id)")
            let enrichment = try await fetchEnrichmentData(for: launch)
            
            var updated = launch
            updated.missionOverview = enrichment.missionOverview
            updated.insights = enrichment.insights
            
            Self.logger.info("✅ ENRICHMENT FLOW: API enrichment successful for \(launch.id): overview length=\(enrichment.missionOverview?.count ?? 0), insights count=\(enrichment.insights?.count ?? 0)")
            
            // Cache this real API-generated enrichment
            let entry = CacheEntry(launch: updated, timestamp: Date())
            cache.setObject(entry, forKey: cacheKey)
            
            return updated
        } catch {
            // Step 4: If API fails, fall back to generated content
            Self.logger.warning("⚠️ ENRICHMENT FLOW: API enrichment failed, using fallback data: \(error.localizedDescription)")
            let fallbackEnrichment = Enrichment.createFallbackEnrichment(for: launch)
            
            var updated = launch
            updated.missionOverview = fallbackEnrichment.missionOverview
            updated.insights = fallbackEnrichment.insights
            
            // Cache the fallback enrichment
            let entry = CacheEntry(launch: updated, timestamp: Date())
            cache.setObject(entry, forKey: cacheKey)
            
            return updated
        }
    }
    
    func enrichLaunches(_ launches: [Launch]) async -> [Launch] {
        return await withTaskGroup(of: Launch.self) { group in
            var inProgress = 0
            var remaining = launches
            
            while inProgress < maxConcurrentRequests && !remaining.isEmpty {
                let launch = remaining.removeFirst()
                group.addTask {
                    do {
                        return try await self.enrichLaunch(launch)
                    } catch {
                        return launch
                    }
                }
                inProgress += 1
            }
            
            var enrichedLaunches: [Launch] = []
            for await launch in group {
                enrichedLaunches.append(launch)
                if !remaining.isEmpty {
                    let nextLaunch = remaining.removeFirst()
                    group.addTask {
                        do {
                            return try await self.enrichLaunch(nextLaunch)
                        } catch {
                            return nextLaunch
                        }
                    }
                }
            }
            return enrichedLaunches
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Helper Methods
    
    private func createPromptForLaunch(_ launch: Launch) -> String {
        """
        Generate a concise AI-enriched summary for this rocket launch.

        **Launch Details:**
        - **Mission Name:** \(launch.missionName)
        - **Launch Provider:** \(launch.provider)
        - **Rocket:** \(launch.rocketName)
        - **Scheduled Date & Time:** \(launch.formattedNet(style: .dateAndTime))
        - **Launch Location:** \(launch.location)

        **Output Requirements:**
        - A **brief mission overview** (max **300 characters**).
        - **2-3 key insights** about the mission, technology, or historical significance.

        **Return JSON format only:**
        ```json
        {
          "missionOverview": "Concise mission summary here.",
          "insights": [
            "First insight about the mission.",
            "Second technical or historical insight.",
            "Optional third insight (if relevant)."
          ]
        }
        ```

        **Important:**
        - Response must be **pure JSON** (no extra text, code fences, or explanations).
        - Keep insights **factual, engaging, and relevant**.
        - Prioritize **mission objectives, unique details, or interesting facts**.
        """
    }
    
    private func extractJSON(from content: String) -> String {
        if let startIndex = content.firstIndex(of: "{"),
           let endIndex = content.lastIndex(of: "}") {
            let jsonString = String(content[startIndex...endIndex])
            Self.logger.info("extractJSON: Extracted JSON: \(jsonString)")
            return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            Self.logger.warning("extractJSON: Failed to find JSON block, returning trimmed: \(trimmed)")
            return trimmed
        }
    }
    
    private func getAPIKey() throws -> String {
        guard let apiKey = Config.shared.grokAPIKey, !apiKey.isEmpty else {
            throw GrokError.missingAPIKey
        }
        return apiKey
    }
    
    private func fetchEnrichmentData(for launch: Launch) async throws -> Enrichment {
        // Check if API key is available, if not use fallback data
        guard let apiKey = Config.shared.grokAPIKey, !apiKey.isEmpty else {
            Self.logger.warning("No API key available, using fallback enrichment data for launch: \(launch.missionName)")
            return Enrichment.createFallbackEnrichment(for: launch)
        }
        
        var attempt = 0
        let maxRetries = 2
        while attempt <= maxRetries {
            do {
                return try await requestEnrichment(launch)
            } catch {
                if attempt == maxRetries {
                    // After max retries, use fallback data instead of throwing
                    Self.logger.warning("API enrichment failed after \(maxRetries) attempts, using fallback data: \(error.localizedDescription)")
                    return Enrichment.createFallbackEnrichment(for: launch)
                }
                attempt += 1
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * attempt))
            }
        }
        
        // This should never be reached due to the changes above, but kept for safety
        return Enrichment.createFallbackEnrichment(for: launch)
    }
    
    private func requestEnrichment(_ launch: Launch) async throws -> Enrichment {
        // Generate a custom prompt for this specific launch with mission details
        let prompt = createPromptForLaunch(launch)
        Self.logger.info("🔍 REQUEST: Creating enrichment prompt for \(launch.missionName)")
        
        do {
            // Set up the request with API key authentication
            let model = defaultModel
            let apiKey = try getAPIKey()
            Self.logger.info("🔑 REQUEST: Using model: \(model) with API key (truncated): \(apiKey.prefix(5))...")
            
            // Build single-message chat completion request
            let request = GrokRequest(model: model, messages: [.init(role: "user", content: prompt)])
            let urlRequest = try request.urlRequest(endpoint: endpoint, apiKey: apiKey)
            
            // Make the network request to Grok API
            Self.logger.info("🌐 REQUEST: Sending request to \(self.endpoint) for \(launch.missionName)")
            let (data, response) = try await self.session.data(for: urlRequest)
            
            // Verify we got a successful response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                Self.logger.error("❌ RESPONSE: Failed with status code \(statusCode)")
                throw GrokError.invalidResponse(statusCode: statusCode)
            }
            
            // Decode the API response
            Self.logger.info("✅ RESPONSE: Received \(data.count) bytes from API for \(launch.missionName)")
            let decodedResponse = try decoder.decode(GrokResponse.self, from: data)
            
            // Log the raw text response from the API to help with debugging
            let rawContent = decodedResponse.choices.first?.message.content ?? "Empty"
            Self.logger.info("📝 RESPONSE: Raw AI content (truncated to 100 chars): \(String(rawContent.prefix(100)))")
            
            // Verify we have a non-empty response
            guard let content = decodedResponse.choices.first?.message.content else {
                Self.logger.error("❌ RESPONSE: Empty content received from API")
                throw GrokError.emptyResponse
            }
            
            // Extract the JSON object from the response text and decode to Enrichment
            let jsonString = extractJSON(from: content)
            Self.logger.info("🔄 PARSING: Extracted JSON of length \(jsonString.count)")
            let enrichment = try decoder.decode(Enrichment.self, from: Data(jsonString.utf8))
            Self.logger.info("✅ PARSING: Successfully parsed enrichment data: overview length=\(enrichment.missionOverview?.count ?? 0), insights count=\(enrichment.insights?.count ?? 0)")
            
            return enrichment
        } catch {
            Self.logger.error("❌ ERROR: Enrichment request failed: \(error.localizedDescription)")
            throw GrokError.enrichmentFailed(launchName: launch.missionName, underlyingError: error)
        }
    }
    
    private func saveEnrichedLaunches(_ launches: [Launch]) {
        if let data = try? JSONEncoder().encode(launches) {
            UserDefaults.standard.set(data, forKey: enrichedCacheKey)
        }
    }

    private func loadEnrichedLaunches() -> [Launch]? {
        guard let data = UserDefaults.standard.data(forKey: enrichedCacheKey) else { return nil }
        return try? JSONDecoder().decode([Launch].self, from: data)
    }
}

// MARK: - Request/Response Models
struct GrokRequest: Codable {
    let model: String
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    func urlRequest(endpoint: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw GrokError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(self)
        return request
    }
}

struct GrokResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

enum GrokError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse(statusCode: Int)
    case emptyResponse
    case enrichmentFailed(launchName: String, underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Grok API key is missing or empty."
        case .invalidURL:
            return "Invalid Grok API URL."
        case .invalidResponse(let statusCode):
            return "Invalid response from Grok API: \(statusCode)"
        case .emptyResponse:
            return "Empty or malformed response from Grok API."
        case .enrichmentFailed(let launchName, let error):
            return "Failed to enrich launch '\(launchName)': \(error.localizedDescription)"
        }
    }
}
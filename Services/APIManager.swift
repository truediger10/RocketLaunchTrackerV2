import Foundation
import os

// MARK: - Date Parsing Helper
fileprivate func parseDate(_ string: String) -> Date? {
    // Cache formatters for reuse to avoid repeated creation
    struct DateFormatters {
        static let withFractional: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
        
        static let withoutFractional: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }()
    }
    
    // Try with fractional seconds first, then without
    if let date = DateFormatters.withFractional.date(from: string) {
        return date
    }
    return DateFormatters.withoutFractional.date(from: string)
}

// MARK: - API Response Models

struct APINetPrecision: Decodable {
    let id: Int?
    let name: String?
    let abbrev: String?
    let description: String?
}

struct APISpaceDevsResponse: Decodable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [APISpaceDevsLaunch]?
}

struct APISpaceDevsLaunch: Decodable {
    let id: String
    let name: String?
    let net: String?
    let url: String?
    let slug: String?
    let launchDesignator: String?
    let windowStart: String?
    let windowEnd: String?
    let probability: Int?
    let webcastLive: Bool?

    let launchServiceProvider: Provider?
    let pad: Pad?
    let image: APIImage?
    let status: Status?
    let mission: Mission?
    let rocket: Rocket?

    struct Provider: Decodable {
        let id: Int?
        let url: String?
        let name: String?
        let type: ProviderType?

        struct ProviderType: Decodable {
            let id: Int?
            let name: String?
        }
    }

    struct Pad: Decodable {
        let id: Int?
        let url: String?
        let name: String?
        let latitude: Double?
        let longitude: Double?
        let location: Location?

        struct Location: Decodable {
            let id: Int?
            let name: String?
            let countryCode: String?
        }
    }

    struct APIImage: Decodable {
        let id: Int?
        let name: String?
        let imageUrl: String?
        let thumbnailUrl: String?
        let credit: String?
    }

    struct Status: Decodable {
        let id: Int?
        let name: String?
        let abbrev: String?
        let description: String?
    }

    struct Mission: Decodable {
        let id: Int?
        let name: String?
        let type: String?
        let description: String?
        let image: MissionImage?
        let orbit: Orbit?
        let agencies: [Agency]?

        struct MissionImage: Decodable {
            let id: Int?
            let name: String?
            let imageUrl: String?
            let thumbnailUrl: String?
            let credit: String?

            enum CodingKeys: String, CodingKey {
                case id, name
                case imageUrl = "image_url"
                case thumbnailUrl = "thumbnail_url"
                case credit
            }
        }

        struct Orbit: Decodable {
            let id: Int?
            let name: String?
            let abbrev: String?
            let celestialBody: CelestialBody?

            struct CelestialBody: Decodable {
                let id: Int?
                let name: String?
            }
        }

        struct Agency: Decodable {
            let id: Int
            let url: String?
            let name: String
            let type: AgencyType

            struct AgencyType: Decodable {
                let id: Int?
                let name: String?
            }
        }
    }

    struct Rocket: Decodable {
        let id: Int?
        let configuration: Configuration?

        struct Configuration: Decodable {
            let id: Int?
            let url: String?
            let name: String?
            let fullName: String?
            let variant: String?
        }
    }

    // MARK: - Model Conversion
    func toLaunch() -> Launch? {
        // Validate required date
        guard let netString = net, let netDate = parseDate(netString) else {
            APIManager.logger.warning("Could not parse net date: \(self.net ?? "nil") for launch: \(self.name ?? "Unknown")")
            return nil
        }
        
        // Parse optional dates
        let windowStartDate = windowStart.flatMap { parseDate($0) }
        let windowEndDate = windowEnd.flatMap { parseDate($0) }
        
        // Get rocket name with fallbacks
        let rocketName = rocket?.configuration?.fullName
                         ?? rocket?.configuration?.name
                         ?? "Unknown Rocket"
        
        // Parse image URL
        let imageURL = image?.imageUrl.flatMap { URL(string: $0) }

        // Build mission data if available
        let launchMission: Launch.Mission? = {
            guard let mission = mission else { return nil }

            let orbit = mission.orbit.flatMap {
                Launch.Mission.Orbit(
                    id: $0.id ?? 0,
                    name: $0.name ?? "Unknown Orbit",
                    abbrev: $0.abbrev ?? "N/A"
                )
            }

            let agencies = mission.agencies?.compactMap {
                Launch.Mission.Agency(
                    id: $0.id,
                    url: $0.url ?? "",
                    name: $0.name,
                    type: $0.type.name ?? "Unknown"
                )
            }

            return Launch.Mission(
                id: mission.id ?? -1,
                name: mission.name ?? "Unknown Mission",
                type: mission.type ?? "Unknown",
                missionDescription: mission.description,
                image: mission.image?.imageUrl.flatMap { URL(string: $0) },
                orbit: orbit,
                agencies: agencies,
                infoUrls: [],
                vidUrls: []
            )
        }()

        // Create and return the Launch model
        return Launch(
            id: id,
            name: name ?? "Unnamed Launch",
            net: netDate,
            provider: launchServiceProvider?.name ?? "Unknown Provider",
            location: pad?.name ?? "Unknown Location",
            padLatitude: pad?.latitude,
            padLongitude: pad?.longitude,
            missionOverview: mission?.description,
            insights: nil,
            image: imageURL,
            rocketName: rocketName,
            isFavorite: false,
            notificationsEnabled: false,
            status: status?.name,
            missionName: mission?.name ?? (name ?? "Unknown Mission"),
            probability: probability,
            url: url,
            slug: slug,
            launchDesignator: launchDesignator,
            windowStart: windowStartDate,
            windowEnd: windowEndDate,
            webcastLive: webcastLive,
            mission: launchMission
        )
    }
}

// MARK: - Error Handling Helper
private func printDecodingError(_ error: DecodingError, data: Data) {
    APIManager.logger.error("Decoding Error: \(error.localizedDescription)")
    
    switch error {
    case .typeMismatch(let key, let context):
        APIManager.logger.error("Type mismatch for key: \(String(describing: key), privacy: .public). \(context.debugDescription, privacy: .public)")
        APIManager.logger.error("CodingPath: \(String(describing: context.codingPath), privacy: .public)")
        
    case .valueNotFound(let key, let context):
        APIManager.logger.error("Value not found for key: \(String(describing: key), privacy: .public). \(context.debugDescription, privacy: .public)")
        APIManager.logger.error("CodingPath: \(String(describing: context.codingPath), privacy: .public)")
        
    case .keyNotFound(let key, let context):
        APIManager.logger.error("Key not found: \(String(describing: key), privacy: .public). \(context.debugDescription, privacy: .public)")
        APIManager.logger.error("CodingPath: \(String(describing: context.codingPath), privacy: .public)")
        
    case .dataCorrupted(let context):
        APIManager.logger.error("Data corrupted: \(context.debugDescription, privacy: .public)")
        APIManager.logger.error("CodingPath: \(context.codingPath, privacy: .public)")
        
    default:
        APIManager.logger.error("General decoding error: \(error.localizedDescription, privacy: .public)")
    }

    // Log a sample of the data to help with debugging
    if let rawString = String(data: data, encoding: .utf8) {
        let truncatedString: String = String(rawString.prefix(2000))
        APIManager.logger.info("Raw JSON (truncated to 2k): \(truncatedString, privacy: .public)")
    }
}

// MARK: - API Manager
final class APIManager {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = APIManager()
    
    /// Logger for structured logging
    static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "APIManager")
    
    /// URL session for network requests
    private let session: URLSession
    
    /// API endpoint URL
    private let endpoint = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=50"
    
    // MARK: - Caching Properties
    
    /// The time of the last successful fetch
    private var lastFetchTime: Date?
    
    /// Cached response data
    private var cachedResponse: [Launch]?
    
    /// How long cached data remains valid (10 minutes)
    private let cacheDuration: TimeInterval = 10 * 60
    
    // MARK: - Rate Limiting Properties
    
    /// Minimum time between requests (3 seconds)
    private let minimumRequestInterval: TimeInterval = 3
    
    /// When the last request was made
    private var lastRequestTime: Date?
    
    /// Maximum number of retry attempts
    private let maxRetries = 3
    
    /// Precomputed backoff times for retries (in seconds)
    private let backoffTimes: [TimeInterval] = [0, 3, 9, 27]
    
    // MARK: - Initialization
    
    private init() {
        // Configure URL session for optimal performance
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.urlCache = URLCache.shared
        config.httpMaximumConnectionsPerHost = 5
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Fetches rocket launch data from the API or cache
    /// - Parameters:
    ///   - forceRefresh: Whether to ignore cached data and fetch fresh data
    ///   - ensureMinimum: Minimum number of launches to return
    /// - Returns: Array of Launch objects
    func fetchLaunches(forceRefresh: Bool = false, ensureMinimum: Int = 50) async throws -> [Launch] {
        // Check cache first (unless force refresh requested)
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           let cached = cachedResponse,
           cached.count >= ensureMinimum {
            Self.logger.info("Using cached response from \(String(describing: lastFetch))")
            return cached
        }
        
        // Enforce rate limiting
        await enforceRateLimit()
        
        // Fetch with retry logic
        return try await fetchWithRetry(ensureMinimum: ensureMinimum)
    }
    
    // MARK: - Private Methods
    
    /// Enforces rate limiting by waiting if needed
    private func enforceRateLimit() async {
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            let waitTime = minimumRequestInterval - Date().timeIntervalSince(lastRequest)
            
            if waitTime > 0 {
                do {
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                } catch {
                    // Sleep was interrupted, but we can proceed anyway
                    Self.logger.warning("Rate limit sleep interrupted: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Performs fetch with retry logic
    private func fetchWithRetry(ensureMinimum: Int) async throws -> [Launch] {
        var retryCount = 0
        var lastError: Error?
        
        // Try fetching with retries
        while retryCount < self.maxRetries && ((cachedResponse?.count ?? 0) < ensureMinimum) {
            do {
                lastRequestTime = Date()
                let launches = try await performFetchRequest()
                
                // Update cache
                lastFetchTime = Date()
                cachedResponse = launches
                
                return launches
            } catch {
                // Handle errors and retry
                lastError = error
                retryCount += 1
                
                if retryCount < self.maxRetries {
                    // Get backoff time from precomputed array to avoid pow() ambiguity
                    let backoffIndex = min(retryCount, backoffTimes.count - 1)
                    let backoffSeconds: TimeInterval = self.backoffTimes[backoffIndex]
                    
                    Self.logger.warning("Retrying in \(backoffSeconds) seconds... (Attempt \(retryCount+1) of \(self.maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                }
            }
        }
        
        // Return expired cache if available and large enough
        if let cached = cachedResponse, cached.count >= ensureMinimum {
            Self.logger.warning("Using expired cached response after \(retryCount) attempts")
            return cached
        }
        
        // All retries failed, throw error
        Self.logger.error("fetchLaunches returning after all retries. Last error: \(String(describing: lastError))")
        throw lastError ?? URLError(.unknown)
    }
    
    /// Performs the actual network request
    private func performFetchRequest() async throws -> [Launch] {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        // Perform request
        let (data, response) = try await session.data(from: url)
        lastRequestTime = Date()

        // Log response sample to aid debugging
        if let rawString = String(data: data, encoding: .utf8) {
            Self.logger.info("Raw JSON response (truncated to 1k): \(String(rawString.prefix(1000)))")
        }

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check status code
        switch httpResponse.statusCode {
        case 200...299:
            // Success, continue processing
            break
            
        case 429:
            // Rate limited
            Self.logger.warning("Rate limited (429). Backing off.")
            throw URLError(.userAuthenticationRequired)
            
        case 500...599:
            // Server error
            Self.logger.error("Server error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
            
        default:
            // Other error
            Self.logger.error("HTTP error: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        // Configure and use decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            // Decode response
            let apiResponse = try decoder.decode(APISpaceDevsResponse.self, from: data)
            
            // Check for empty results
            if apiResponse.results?.isEmpty ?? true {
                Self.logger.info("No new launches received, keeping cached data.")
                return cachedResponse ?? []
            }
            
            // Validate response data
            guard let rawLaunches = apiResponse.results else {
                return []
            }
            
            // Convert API models to domain models
            let converted = rawLaunches.compactMap { $0.toLaunch() }
            
            Self.logger.info("Successfully converted \(converted.count) launches.")
            Self.logger.info("performFetchRequest returning \(converted.count) item(s).")
            
            return converted
        } catch let decodingError as DecodingError {
            // Handle decoding errors with detailed logging
            printDecodingError(decodingError, data: data)
            throw decodingError
        } catch {
            // Handle other errors
            Self.logger.error("General error: \(error.localizedDescription)")
            throw error
        }
    }
}
// This file is not currently in use but kept for potential future integration with OpenAI.

import Foundation

actor OpenAIService {
    static let shared = OpenAIService()
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let apiKey = Config.shared.openAIAPIKey
    private let cache = NSCache<NSString, CacheEntry>()
    private let maxConcurrentTasks = 5

    class CacheEntry {
        let launch: Launch
        let timestamp: Date
        
        init(launch: Launch, timestamp: Date) {
            self.launch = launch
            self.timestamp = timestamp
        }
    }

    func enrichLaunch(_ launch: Launch) async -> Launch {
        let cacheKey = "\(launch.id)" as NSString
        if let entry = cache.object(forKey: cacheKey),
           Date().timeIntervalSince(entry.timestamp) < Config.shared.cacheExpirationInterval {
            print("🤖 Using cached enrichment for launch: \(launch.missionName)")
            return entry.launch
        }

        var updated = launch
        let prompt = """
        Provide for this launch:
        - Mission overview (max 300 chars)
        - 2-3 insights about the mission
        Launch: \(launch.missionName), Provider: \(launch.provider), Date: \(launch.formattedNet(style: .dateAndTime)), Location: \(launch.location)
        Return as JSON: {"missionOverview": "", "insights": ["", "", ""]}
        """
        print("🤖 Enriching launch: \(launch.missionName) with prompt: \(prompt)")
        do {
            let request = OpenAIRequest(model: "gpt-4", messages: [.init(role: "user", content: prompt)])
            let urlRequest = try request.urlRequest(endpoint: endpoint, apiKey: apiKey)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            if let responseString = String(data: data, encoding: .utf8) {
                print("🤖 OpenAI response: \(responseString)")
            } else {
                print("🤖 Failed to decode OpenAI response as UTF-8")
            }
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let enrichment = try JSONDecoder().decode(Enrichment.self, from: response.choices[0].message.content.data(using: .utf8)!)
            updated.missionOverview = enrichment.missionOverview
            updated.insights = enrichment.insights
            cache.setObject(CacheEntry(launch: updated, timestamp: Date()), forKey: cacheKey)
            print("🤖 Successfully enriched launch: \(launch.missionName)")
        } catch {
            print("🤖 Enrichment failed for \(launch.missionName): \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("🤖 URL Error details - Code: \(urlError.errorCode), Reason: \(urlError.localizedDescription)")
            }
        }
        return updated
    }

    func enrichLaunches(_ launches: [Launch]) async -> [Launch] {
        await withTaskGroup(of: Launch.self) { group in
            var activeTasks = 0
            for launch in launches {
                if activeTasks >= maxConcurrentTasks {
                    if let nextLaunch = await group.next() {
                        activeTasks -= 1
                        group.addTask { await self.enrichLaunch(nextLaunch) }
                        activeTasks += 1
                    }
                }
                group.addTask { await self.enrichLaunch(launch) }
                activeTasks += 1
            }
            var enrichedLaunches: [Launch] = []
            for await launch in group {
                enrichedLaunches.append(launch)
            }
            return enrichedLaunches
        }
    }
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]

    struct Message: Codable {
        let role: String
        let content: String
    }

    func urlRequest(endpoint: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(self)
        return request
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}


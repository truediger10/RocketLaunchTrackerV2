import Foundation

/// A struct representing enrichment data for a rocket launch.
struct Enrichment: Codable, Equatable {
    /// A brief overview of the mission.
    let missionOverview: String?
    
    /// A list of insights related to the mission.
    let insights: [String]?
    
    /// Initializes a new instance of `Enrichment`.
    /// - Parameters:
    ///   - missionOverview: A brief overview of the mission.
    ///   - insights: A list of insights related to the mission.
    init(missionOverview: String? = nil, insights: [String]? = nil) {
        self.missionOverview = missionOverview
        self.insights = insights
    }
    
    /// Creates sample/fallback enrichment for a launch when API data isn't available
    static func createFallbackEnrichment(for launch: Launch) -> Enrichment {
        let missionOverview = "A \(launch.rocketName) rocket launching from \(launch.location) carrying the \(launch.missionName) mission by \(launch.provider)."
        
        var insights: [String] = [
            "This mission uses the \(launch.rocketName), known for its reliability and performance in the space industry.",
            "Launching from \(launch.location), this site has supported numerous successful missions in the past."
        ]
        
        // Add some variety based on the mission name
        if launch.missionName.contains("Starlink") {
            insights.append("Part of SpaceX's Starlink constellation, providing global broadband internet coverage via a network of satellites.")
        } else if launch.missionName.contains("Crew") {
            insights.append("This is a crewed mission transporting astronauts, highlighting the importance of human spaceflight capabilities.")
        } else if launch.provider.contains("NASA") {
            insights.append("NASA continues to advance space exploration through various scientific and technological missions.")
        } else if launch.missionName.contains("Satellite") || launch.missionName.contains("SAT") {
            insights.append("Satellite deployments like this one are critical for communications, Earth observation, and scientific research.")
        }
        
        return Enrichment(missionOverview: missionOverview, insights: insights)
    }
    
    // NOTE: Removed redundant createFallbackData method to fix redeclaration error
}
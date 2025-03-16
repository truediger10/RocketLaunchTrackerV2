import SwiftUI
import Foundation

/// Provides a standardized representation of launch information,
/// optimizing the display logic needed by the UI.
struct LaunchInfoDisplay {
    let launch: Launch
    
    // MARK: - Formatted Text
    
    /// Displays the name of the provider or agency.
    var provider: String { launch.provider }
    
    /// Displays the mission name.
    var missionName: String { launch.missionName }
    
    /// The type of rocket used for the launch.
    var rocketType: String { launch.rocketName }
    
    /// A short text describing the launch location.
    var location: String { launch.location }
    
    /// Returns a medium-style date string (e.g., "Mar 10, 2025").
    var launchDate: String { launch.formattedNet(style: .dateOnly) }
    
    /// Returns a short-style time string (e.g., "2:15 PM").
    var launchTime: String { launch.formattedNet(style: .timeOnly) }
    
    /// Returns a combined date and time (e.g., "Mar 10, 2025 at 2:15 PM").
    var launchDateTime: String { launch.formattedNet(style: .dateAndTime) }
    
    /// The current status of the launch, such as "Go" or "Hold".
    var status: String? { launch.status }
    
    /// A short, AI-generated overview of the mission, if available.
    var missionOverview: String? { launch.missionOverview }
    
    /// An array of bullet points or interesting facts about the mission.
    var insights: [String]? { launch.insights }
    
    /// Renders the probability as a string with a '%' sign if available.
    var probabilityText: String? {
        guard let probability = launch.probability else { return nil }
        return "\(probability)% launch probability"
    }
    
    // MARK: - Relative Time
    
    /// Provides a human-readable countdown or time-to-launch phrase.
    var relativeTimeDescription: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: launch.net).day ?? 0
        
        if days < 0 {
            return "Launched"
        } else if days == 0 {
            let hours = Calendar.current.dateComponents([.hour], from: Date(), to: launch.net).hour ?? 0
            if hours < 1 {
                return "Launching soon"
            } else {
                return "Launching in \(hours) \(hours == 1 ? "hour" : "hours")"
            }
        } else if days == 1 {
            return "Launching tomorrow"
        } else if days < 7 {
            return "Launching in \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "Launching in \(weeks) \(weeks == 1 ? "week" : "weeks")"
        } else {
            let months = days / 30
            return "Launching in \(months) \(months == 1 ? "month" : "months")"
        }
    }
    
    /// Returns a grouping label (e.g., "Next 24 Hours" or "This Month") based on how far away the launch is.
    var timePeriod: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: launch.net).day ?? 0
        if days <= 1 {
            return "Next 24 Hours"
        } else if days <= 7 {
            return "This Week"
        } else if days <= 30 {
            return "This Month"
        } else {
            return "Upcoming"
        }
    }
    
    // MARK: - Styling Helpers
    
    /// Returns a color reflecting the launch status or success probability.
    var statusColor: Color {
        if let status = launch.status?.lowercased() {
            if status.contains("go") || status.contains("success") {
                return Color.green.opacity(0.8)
            } else if status.contains("hold") || status.contains("delay") {
                return Color.orange.opacity(0.8)
            } else if status.contains("fail") || status.contains("abort") {
                return Color.red.opacity(0.8)
            }
        }
        
        if let probability = launch.probability {
            if probability > 80 {
                return Color.green.opacity(0.8)
            } else if probability > 50 {
                return Color.orange.opacity(0.8)
            } else {
                return Color.red.opacity(0.8)
            }
        }
        
        return Styles.primaryAccent.opacity(0.8) // Primary accent color
    }
    
    /// Returns an SF Symbol name correlating to the launch status,
    /// used as an icon next to the status text.
    var statusSymbol: String {
        if let status = launch.status?.lowercased() {
            if status.contains("go") || status.contains("success") {
                return "checkmark.circle.fill"
            } else if status.contains("hold") || status.contains("delay") {
                return "pause.circle.fill"
            } else if status.contains("fail") || status.contains("abort") {
                return "xmark.circle.fill"
            }
        }
        
        return "clock.fill"
    }
}
struct LaunchInfoDisplay_Previews: PreviewProvider {
    static var previews: some View {
        let launch = Launch(
            id: "1",
            name: "Starlink 4-10",
            net: Date(),
            provider: "SpaceX",
            location: "Cape Canaveral, FL",
            padLatitude: 28.56230196762057,
            padLongitude: -80.57735682733052,
            missionOverview: "A batch of 60 Starlink satellites for SpaceX's internet constellation.",
            insights: ["First stage booster has flown 10 times before.", "Fairing halves are new."],
            image: URL(string: "https://example.com/image.jpg"),
            rocketName: "Falcon 9",
            isFavorite: false,
            notificationsEnabled: true,
            status: "Go for Launch",
            missionName: "Starlink 4-10",
            probability: 90,
            url: "https://example.com",
            slug: "starlink-4-10",
            launchDesignator: "Starlink 4-10",
            windowStart: Date(),
            windowEnd: Date(),
            webcastLive: false,
            mission: Launch.Mission(
                id: 1,
                name: "Starlink 4-10",
                type: "Communications",
                missionDescription: "A batch of 60 Starlink satellites for SpaceX's internet constellation.",
                image: URL(string: "https://example.com/image.jpg"),
                orbit: Launch.Mission.Orbit(
                    id: 1,
                    name: "Low Earth Orbit",
                    abbrev: "LEO"
                ),
                agencies: [
                    Launch.Mission.Agency(
                        id: 1,
                        url: "https://example.com",
                        name: "SpaceX",
                        type: "Commercial"
                    )
                ],
                infoUrls: ["https://example.com"],  // URL(s) for additional mission info
                vidUrls: ["https://example.com"]   // URL(s) for mission webcast
            )
        )
        
        return VStack {
            Text("Provider: \(LaunchInfoDisplay(launch: launch).provider)")
            Text("Mission Name: \(LaunchInfoDisplay(launch: launch).missionName)")
            Text("Rocket Type: \(LaunchInfoDisplay(launch: launch).rocketType)")
            Text("Location: \(LaunchInfoDisplay(launch: launch).location)")
            Text("Launch Date: \(LaunchInfoDisplay(launch: launch).launchDate)")
            Text("Launch Time: \(LaunchInfoDisplay(launch: launch).launchTime)")
            Text("Launch Date & Time: \(LaunchInfoDisplay(launch: launch).launchDateTime)")
            Text("Status: \(LaunchInfoDisplay(launch: launch).status ?? "Unknown")")
            Text("Mission Overview: \(LaunchInfoDisplay(launch: launch).missionOverview ?? "None")")
            Text("Insights: \(LaunchInfoDisplay(launch: launch).insights?.joined(separator: ", ") ?? "None")")
            Text("Probability: \(LaunchInfoDisplay(launch: launch).probabilityText ?? "Unknown")")
            Text("Relative Time: \(LaunchInfoDisplay(launch: launch).relativeTimeDescription)")
            Text("Time Period: \(LaunchInfoDisplay(launch: launch).timePeriod)")
        }
        .padding()
    }
}

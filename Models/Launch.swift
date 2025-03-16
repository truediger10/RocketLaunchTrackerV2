import Foundation

/// Represents a single rocket launch with associated details and user preferences.
struct Launch: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let net: Date
    let provider: String
    let location: String
    let padLatitude: Double?
    let padLongitude: Double?
    var missionOverview: String?
    var insights: [String]?
    var image: URL?
    let rocketName: String
    var isFavorite: Bool
    var notificationsEnabled: Bool
    let status: String?
    let missionName: String
    let probability: Int?
    let url: String?
    let slug: String?
    let launchDesignator: String?
    let windowStart: Date?
    let windowEnd: Date?
    let webcastLive: Bool?
    let mission: Mission?

    struct Mission: Codable, Equatable {
        let id: Int
        let name: String
        let type: String
        let missionDescription: String?
        let image: URL?
        let orbit: Orbit?
        let agencies: [Agency]?
        let infoUrls: [String]
        let vidUrls: [String]

        enum CodingKeys: String, CodingKey {
            case id, name, type, orbit, agencies
            case missionDescription = "description"
            case image
            case infoUrls = "info_urls"
            case vidUrls = "vid_urls"
        }

        struct Orbit: Codable, Equatable {
            let id: Int
            let name: String
            let abbrev: String
        }

        struct Agency: Codable, Equatable {
            let id: Int
            let url: String
            let name: String
            let type: String
        }
    }

    // MARK: - Date Formatting
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        return df
    }()

    enum DateStyle {
        case dateOnly, timeOnly, dateAndTime
    }

    func formattedNet(style: DateStyle) -> String {
        switch style {
        case .dateOnly:
            Self.dateFormatter.dateStyle = .medium
            Self.dateFormatter.timeStyle = .none
        case .timeOnly:
            Self.dateFormatter.dateStyle = .none
            Self.dateFormatter.timeStyle = .short
        case .dateAndTime:
            Self.dateFormatter.dateStyle = .medium
            Self.dateFormatter.timeStyle = .short
        }
        return Self.dateFormatter.string(from: net)
    }

    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: Launch, rhs: Launch) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.net == rhs.net &&
        lhs.provider == rhs.provider &&
        lhs.location == rhs.location &&
        lhs.padLatitude == rhs.padLatitude &&
        lhs.padLongitude == rhs.padLongitude &&
        lhs.missionOverview == rhs.missionOverview &&
        lhs.insights == rhs.insights &&
        lhs.image == rhs.image &&
        lhs.rocketName == rhs.rocketName &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.notificationsEnabled == rhs.notificationsEnabled &&
        lhs.status == rhs.status &&
        lhs.missionName == rhs.missionName &&
        lhs.probability == rhs.probability &&
        lhs.url == rhs.url &&
        lhs.slug == rhs.slug &&
        lhs.launchDesignator == rhs.launchDesignator &&
        lhs.windowStart == rhs.windowStart &&
        lhs.windowEnd == rhs.windowEnd &&
        lhs.webcastLive == rhs.webcastLive
    }
}

//
//  RocketType.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/9/25.
//


import Foundation

/// A simple structure representing a type of rocket and the launches associated with it.
struct RocketType: Identifiable {
    /// The rocket name itself serves as a unique identifier
    var id: String { rocket }
    
    /// The rocket name (e.g., "Falcon 9")
    let rocket: String
    
    /// A representative image URL for this rocket
    let image: URL
    
    /// The collection of launches that use this rocket
    let launches: [Launch]
}
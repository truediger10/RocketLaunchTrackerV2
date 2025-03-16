import Foundation
import SwiftUI
import Combine
import os

/// Centralized service for managing favorites across the app
class FavoriteService: ObservableObject {
    @Published var favorites: [String: Bool] = [:]
    
    private let favoritesKey = "FavoriteLaunches"
    
    static let shared = FavoriteService()
    
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "FavoriteService")

    private init() {
        loadFavorites()
    }
    
    func isFavorite(launchId: String) -> Bool {
        return favorites[launchId] == true
    }
    
    func toggleFavorite(launchId: String, isFavorite: Bool? = nil) {
        if let isFavorite = isFavorite {
            favorites[launchId] = isFavorite
        } else {
            favorites[launchId] = !(favorites[launchId] == true)
        }
        saveFavorites()
    }
    
    func addFavorite(_ launch: Launch) {
        favorites[launch.id] = true
        saveFavorites()
    }
    
    func removeFavorite(launchId: String) {
        favorites[launchId] = false
        saveFavorites()
    }
    
    func getAllFavorites() -> [String] {
        favorites.filter { $0.value }.map { $0.key }
    }
    
    func setFavorites(launches: [Launch]) {
        for launch in launches {
            favorites[launch.id] = true
        }
        saveFavorites()
    }
    
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return }
        
        do {
            if let dict = try? JSONDecoder().decode([String: Bool].self, from: data) {
                favorites = dict
                return
            }
            
            let decoded = try JSONDecoder().decode([Launch].self, from: data)
            for launch in decoded {
                favorites[launch.id] = true
            }
        } catch {
            Self.logger.error("Failed to load favorites: \(error.localizedDescription)")
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
}
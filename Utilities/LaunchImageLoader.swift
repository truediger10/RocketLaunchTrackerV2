import SwiftUI
import Combine

/// A dedicated image loader that improves caching, loading performance, and UI consistency
/// throughout the app for rocket launch images.
class LaunchImageLoader: ObservableObject, @unchecked Sendable {
    
    static let shared = LaunchImageLoader()
    
    @Published private(set) var imageCache = [String: UIImage]()
    private var cancellables = Set<AnyCancellable>()
    private var preloadQueue = DispatchQueue(label: "com.spacelaunch.imagePreloadQueue", qos: .utility)
    
    // Use a serial queue for synchronization instead of NSLock
    private let syncQueue = DispatchQueue(label: "com.spacelaunch.imageSyncQueue")
    private var activePreloads = Set<String>()
    private let maxCacheEntries = 20
    
    private init() {}
    
    /// Loads an image from cache or network with optimized handling
    /// - Parameters:
    ///   - url: The image URL
    ///   - id: The launch ID to use as a cache key
    /// - Returns: A publisher that emits the loaded image or error
    func loadImage(from url: URL, id: String) -> AnyPublisher<UIImage, Error> {
        // Check memory cache first (fastest)
        if let cachedImage = imageCache[id] {
            return Just(cachedImage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Future<UIImage, Error> { [weak self] promise in
            Task {
                guard let self else { return }
                if let cachedData = await CacheManager.shared.getCachedImage(for: id),
                   let image = UIImage(data: cachedData) {
                    DispatchQueue.main.async {
                        self.imageCache[id] = image
                        promise(.success(image))
                    }
                } else {
                    // Check if we're already loading this image using the sync queue
                    let isAlreadyLoading = self.syncQueue.sync {
                        let alreadyLoading = self.activePreloads.contains(id)
                        if !alreadyLoading {
                            self.activePreloads.insert(id)
                        }
                        return alreadyLoading
                    }
                    
                    // If already loading, don't start a second request
                    if isAlreadyLoading {
                        // Wait for a bit and check cache again
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        if let cachedImage = self.imageCache[id] {
                            promise(.success(cachedImage))
                            return
                        }
                    }
                    
                    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        guard let self else { return }
                        
                        // Remove from active preloads when complete
                        defer {
                            _ = self.syncQueue.sync {
                                self.activePreloads.remove(id)
                            }
                        }
                        
                        if let data = data, let image = UIImage(data: data) {
                            Task {
                                await CacheManager.shared.cacheImage(data, for: id)
                                DispatchQueue.main.async {
                                    self.imageCache[id] = image
                                    promise(.success(image))
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                promise(.failure(error ?? URLError(.badServerResponse)))
                            }
                        }
                    }
                    .resume()
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Preloads images for a collection of launches to improve UX
    /// Only preloads the most imminent launches to conserve bandwidth and memory
    /// - Parameter launches: Array of launches to preload images for
    func preloadImages(for launches: [Launch]) {
        // Sort launches by date (closest first)
        let upcomingLaunches = launches
            .filter { $0.net > Date() }
            .sorted { $0.net < $1.net }
            .prefix(5) // Only preload the next 5 launches
        
        // Preload images for upcoming launches first
        preloadQueue.async { [weak self] in
            guard let self = self else { return }
            for launch in upcomingLaunches {
                guard let url = launch.image else { continue }
                
                // Check if we're already loading this image using the sync queue
                let isAlreadyLoading = self.syncQueue.sync {
                    let alreadyLoading = self.activePreloads.contains(launch.id)
                    if !alreadyLoading {
                        self.activePreloads.insert(launch.id)
                    }
                    return alreadyLoading
                }
                
                if isAlreadyLoading || self.imageCache[launch.id] != nil {
                    continue
                }
                
                // Use a background task for preloading
                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            await CacheManager.shared.cacheImage(data, for: launch.id)
                            DispatchQueue.main.async {
                                self.imageCache[launch.id] = image
                            }
                        }
                    } catch {
                        print("Preload failed for \(launch.id): \(error.localizedDescription)")
                    }
                    
                    // Remove from active preloads when complete
                    _ = self.syncQueue.sync {
                        self.activePreloads.remove(launch.id)
                    }
                }
            }
        }
    }
    
    /// Clears the memory cache (disk cache is managed by CacheManager)
    func clearCache() {
        imageCache.removeAll()
    }
    
    /// Clears lower priority cache entries when memory warning occurs
    func handleMemoryWarning() {
        // Keep only the most recent images in memory
        if imageCache.count > maxCacheEntries {
            // Sort is expensive, so only do if we have too many entries
            let excess = imageCache.count - maxCacheEntries
            if excess > 0 {
                let keysToRemove = Array(imageCache.keys).prefix(excess)
                for key in keysToRemove {
                    imageCache.removeValue(forKey: key)
                }
                print("Removed \(excess) images from memory cache due to memory warning")
            }
        }
    }
}

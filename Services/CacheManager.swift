import Foundation
import os

/// A manager for caching and retrieving images both in memory and on disk
actor CacheManager {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = CacheManager()
    
    /// In-memory cache for fast access
    private let imageCache: NSCache<NSString, NSData>
    
    /// Directory where cached images are stored on disk
    private let cacheDirectory: URL
    
    /// File manager for disk operations
    private let fileManager: FileManager
    
    /// File extension for cached images
    private let fileExtension = "jpg"
    
    /// Maximum disk cache size (100MB)
    private let maxDiskCacheSize: UInt64 = 100 * 1024 * 1024
    
    /// Maximum age of cached files (3 days) - shortened from 5
    private let maxCacheAge: TimeInterval = 3 * 24 * 60 * 60
    
    /// Unified logger
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "CacheManager")
    
    // MARK: - Initialization
    
    private init() {
        // Configure the in-memory cache
        imageCache = NSCache<NSString, NSData>()
        imageCache.name = "com.spacelaunch.imageCache"
        imageCache.countLimit = 100 // lowered from 200
        imageCache.totalCostLimit = Int(ProcessInfo.processInfo.physicalMemory / 10) // 10% of RAM
        
        fileManager = FileManager.default
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory,
                                         withIntermediateDirectories: true)
        
        // Start background cleanup
        Task.detached(priority: .background) {
            await self.cleanupDiskCache()
        }
    }
    
    // MARK: - Public Methods
    
    /// Cache image data both in memory and on disk
    func cacheImage(_ data: Data, for id: String) async {
        guard !data.isEmpty else { return }
        
        Self.logger.info("Caching image data for id: \(id)")
        let key = id as NSString
        
        // Cache in memory
        imageCache.setObject(data as NSData, forKey: key)
        
        // Async write to disk
        let fileURL = getFileURL(for: id)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Failed to write image to disk: \(error.localizedDescription)")
        }
    }
    
    /// Retrieve cached image from memory or disk
    func getCachedImage(for id: String) async -> Data? {
        let key = id as NSString
        
        if let cachedData = imageCache.object(forKey: key) as Data? {
            return cachedData
        }
        
        let fileURL = getFileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            if !data.isEmpty {
                imageCache.setObject(data as NSData, forKey: key)
            }
            return data
        } catch {
            Self.logger.error("Failed to read image from disk: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear all cached images from memory and optionally from disk
    func clearCache(includeDisk: Bool = false) async {
        imageCache.removeAllObjects()
        
        if includeDisk {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory,
                                                                   includingPropertiesForKeys: nil)
                for fileURL in fileURLs where fileURL.pathExtension == fileExtension {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                Self.logger.error("Failed to clear disk cache: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove a specific image
    func removeImage(for id: String) async {
        let key = id as NSString
        imageCache.removeObject(forKey: key)
        
        let fileURL = getFileURL(for: id)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Cleans up disk cache
    func cleanupDiskCache() async {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )
            
            let currentDate = Date()
            var filesToRemove = [URL]()
            var fileInfos = [(url: URL, size: UInt64, date: Date)]()
            var totalSize: UInt64 = 0
            
            for fileURL in fileURLs {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   let fileSize = attributes[.size] as? UInt64 {
                    totalSize += fileSize
                    fileInfos.append((fileURL, fileSize, creationDate))
                    if currentDate.timeIntervalSince(creationDate) > maxCacheAge {
                        filesToRemove.append(fileURL)
                    }
                }
            }
            
            // Remove old files
            for fileURL in filesToRemove {
                try? fileManager.removeItem(at: fileURL)
            }
            
            // Check total size
            if totalSize > maxDiskCacheSize {
                Self.logger.warning("Cache size exceeded! Triggering cleanup...")
                removeOldestFiles(untilSizeIs: maxDiskCacheSize * 8 / 10, fileInfos: fileInfos)
            }
            
            Self.logger.info("Disk cache cleaned: \((totalSize / 1024 / 1024))MB remaining")
        } catch {
            Self.logger.error("Failed to clean disk cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func removeOldestFiles(untilSizeIs targetSize: UInt64, fileInfos: [(url: URL, size: UInt64, date: Date)]) {
        var totalSize: UInt64 = 0
        let sortedFiles = fileInfos.sorted { $0.date < $1.date }
        for file in sortedFiles {
            if totalSize <= targetSize { break }
            try? fileManager.removeItem(at: file.url)
            totalSize += file.size
        }
    }
    
    private func getFileURL(for id: String) -> URL {
        let sanitizedID = id.replacingOccurrences(of: "/", with: "_")
                            .replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent("\(sanitizedID).\(fileExtension)")
    }
}
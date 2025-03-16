import Foundation
import os

struct Config {
    // MARK: - Error Types
    
    enum ConfigError: LocalizedError {
        case missingAPIKey(String)
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey(let key):
                return "Missing required API key: \(key)"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = Config()
    
    /// Logger for diagnostics
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "Config")
    
    /// API keys and configuration settings
    var openAIAPIKey: String
    var spaceDevsAPIKey: String
    let grokAPIKey: String?  // Used by GrokService for launch enrichment
    let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    let maxRetries: Int = 3
    
    // MARK: - Initialization
    
    private init() {
        Self.logger.info("🚀 STARTUP: Initializing Config and loading API keys")
        print("🔑 CONFIG: Initializing API key configuration")
        
        func getEnvironmentVariable(_ key: String) throws -> String {
            // Step 1: Try to get from environment variables (set in Xcode scheme)
            Self.logger.info("Checking for environment variable: \(key)")
            print("🔍 CONFIG: Looking for environment variable '\(key)'")
            
            if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
                Self.logger.info("Found environment variable: \(key) (length: \(value.count))")
                print("✅ CONFIG: Found environment variable '\(key)' with length \(value.count)")
                return value
            } else {
                Self.logger.warning("Environment variable not found: \(key)")
                print("⚠️ CONFIG: Environment variable '\(key)' not found or empty")
            }
            
            // Step 2: In DEBUG, try debug keys as fallback
            #if DEBUG
            Self.logger.info("In DEBUG mode, checking debug fallback keys")
            print("🔧 CONFIG: In DEBUG mode, checking debug keys")
            
            let debugKeys = [
                "OPENAI_API_KEY": "sk-debug",
                "SPACEDEVS_API_KEY": "debug-key",
                "GROK_API_KEY": "grok-debug"
            ]
            
            if let debugValue = debugKeys[key] {
                Self.logger.info("Using debug key for: \(key)")
                print("ℹ️ CONFIG: Using debug key for '\(key)'")
                return debugValue
            } else {
                Self.logger.warning("No debug key found for: \(key)")
                print("⚠️ CONFIG: No debug key available for '\(key)'")
            }
            #endif
            
            // Step 3: No key found, throw error
            Self.logger.error("Failed to find API key: \(key)")
            print("❌ CONFIG: No value found for '\(key)' - throwing error")
            throw ConfigError.missingAPIKey(key)
        }
        
        // Load all API keys
        do {
            // Try to load from environment variables first
            Self.logger.info("Attempting to load all API keys")
            print("🔄 CONFIG: Attempting to load all API keys")
            
            self.openAIAPIKey = try getEnvironmentVariable("OPENAI_API_KEY")
            self.spaceDevsAPIKey = try getEnvironmentVariable("SPACEDEVS_API_KEY")
            
            // Note: grokAPIKey uses try? so it can be nil without throwing
            // This is the key used for enrichment via the GrokService
            self.grokAPIKey = try? getEnvironmentVariable("GROK_API_KEY")
            
            // Log the keys (safely truncated for security)
            Self.logger.info("API keys loaded successfully")
            print("🔑 CONFIG: API Keys loaded successfully")
            
            // Truncate keys for logging to avoid exposing full keys
            print("ℹ️ CONFIG: openAIAPIKey: \(openAIAPIKey.prefix(5))...")
            print("ℹ️ CONFIG: spaceDevsAPIKey: \(spaceDevsAPIKey.prefix(5))...")
            
            // For our Grok API key, provide more detailed diagnostics since this
            // is critical for the enrichment functionality
            if let grokKey = grokAPIKey {
                Self.logger.info("grokAPIKey loaded successfully (length: \(grokKey.count))")
                print("✅ CONFIG: grokAPIKey loaded successfully: \(grokKey.prefix(5))..., length: \(grokKey.count)")
                
                // Verify key format - should start with "xai-" for Grok API
                if grokKey.hasPrefix("xai-") {
                    Self.logger.info("grokAPIKey has correct prefix 'xai-'")
                    print("✅ CONFIG: grokAPIKey has correct prefix 'xai-'")
                } else {
                    Self.logger.warning("grokAPIKey doesn't have expected 'xai-' prefix - may not work correctly")
                    print("⚠️ CONFIG: grokAPIKey doesn't have expected 'xai-' prefix")
                }
                
                Self.logger.info("Enrichment via GrokService will use real API data")
                print("ℹ️ CONFIG: Enrichment via GrokService will use real API data")
            } else {
                Self.logger.warning("grokAPIKey is nil - enrichment will use fallback data")
                print("⚠️ CONFIG: grokAPIKey is nil - enrichment will use fallback data")
                print("ℹ️ CONFIG: Launch details will show placeholder content instead of AI-generated insights")
            }
            
        } catch {
            Self.logger.error("Failed to load API keys: \(error.localizedDescription)")
            print("❌ CONFIG: Failed to load API keys: \(error.localizedDescription)")
            
            // In DEBUG mode, use debug keys as last resort
            #if DEBUG
            Self.logger.warning("In DEBUG mode, using fallback debug keys")
            print("🔧 CONFIG: In DEBUG mode, falling back to hardcoded debug keys")
            
            self.openAIAPIKey = "sk-debug"
            self.spaceDevsAPIKey = "debug-key"
            self.grokAPIKey = "grok-debug"
            
            print("ℹ️ CONFIG: Using debug keys - Note: 'grok-debug' will not work for real API calls")
            print("ℹ️ CONFIG: Launch details will show placeholder content instead of AI-generated insights")
            #else
            // In production, can't continue without keys
            Self.logger.critical("Cannot continue without API keys in production mode")
            print("❌ CONFIG: Cannot continue without API keys in production mode")
            fatalError("\(error.localizedDescription)")
            #endif
        }
        
        // Final diagnostic message
        Self.logger.info("Config initialization complete")
        print("✅ CONFIG: Initialization complete - ready for app startup")
    }
}

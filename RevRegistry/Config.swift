import Foundation

struct Config {
    // MARK: - API Configuration
    static let apiBaseURL = "http://localhost:3000/api" // Change to your production URL
    static let productionBaseURL = "https://your-domain.com/api"
    
    // MARK: - Environment Detection
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var currentBaseURL: String {
        return isProduction ? productionBaseURL : apiBaseURL
    }
    
    // MARK: - Authentication
    static let googleClientID = "your-google-client-id" // Replace with your Google OAuth client ID
    
    // MARK: - App Settings
    static let appVersion = "1.0.0"
    static let appName = "Rev Registry"
    
    // MARK: - Default Values
    static let defaultMaintenanceIntervals = [
        "OIL_CHANGE": 5000,
        "TIRE_ROTATION": 7500,
        "BRAKE_SERVICE": 25000,
        "INSPECTION": 12000 // Based on months, converted to approximate miles
    ]
    
    // MARK: - Keychain Keys
    static let authTokenKey = "revregistry.auth.token"
    static let userIdKey = "revregistry.user.id"
    
    // MARK: - UserDefaults Keys
    static let lastSyncKey = "revregistry.last.sync"
    static let onboardingCompleteKey = "revregistry.onboarding.complete"
    
    // MARK: - Network Configuration
    static let requestTimeoutInterval: TimeInterval = 30.0
    static let maxRetryAttempts = 3
}

// MARK: - Environment Variables Extension
extension Config {
    static func getEnvironmentVariable(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
} 
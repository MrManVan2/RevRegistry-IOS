# RevRegistry Advanced Features Implementation Guide

This document covers all the advanced features, business logic, and complex functionality from the RevRegistry web app that need to be implemented in the iOS version.

## 📊 Analytics & Tracking System

### Client-Side Analytics (`analytics.ts`)
**Purpose**: Comprehensive user behavior tracking and performance monitoring

**Key Features:**
- Event tracking with custom properties
- Page view tracking with referrer data
- Performance metrics collection
- Automatic queue management and batching
- Session-based tracking
- User privacy compliance

**iOS Implementation:**
```swift
class AnalyticsManager: ObservableObject {
    private let sessionId = UUID().uuidString
    private var eventQueue: [AnalyticsEvent] = []
    private var isEnabled = false
    private var userId: String?
    
    func track(event: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        let analyticsEvent = AnalyticsEvent(
            event: event,
            properties: properties,
            userId: userId,
            timestamp: Date().timeIntervalSince1970,
            sessionId: sessionId
        )
        
        eventQueue.append(analyticsEvent)
        
        if eventQueue.count >= 50 {
            flush()
        }
    }
    
    func trackFeatureUsage(_ feature: String, action: String, properties: [String: Any]? = nil) {
        var props = properties ?? [:]
        props["feature"] = feature
        props["action"] = action
        track(event: "feature_usage", properties: props)
    }
    
    // Background flush every 30 seconds
    private func setupPeriodicFlush() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.flush()
        }
    }
}
```

### Server-Side Analytics Processing (`analytics-events.ts`)
**Features:**
- Respects user privacy preferences
- Handles anonymous vs authenticated analytics
- Batch processing for performance
- Stores events, page views, and performance metrics

## 🔒 Security & Authentication

### Rate Limiting (`rate-limit.ts`)
**Purpose**: Prevents API abuse and DDoS attacks

**iOS Implementation:**
```swift
class RateLimitManager {
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    
    func checkRateLimit(for endpoint: String, limit: Int, windowMs: TimeInterval) -> Bool {
        let now = Date()
        let key = endpoint
        
        // Clean expired entries
        requestCounts = requestCounts.filter { $0.value.resetTime > now }
        
        var rateData = requestCounts[key] ?? (count: 0, resetTime: now.addingTimeInterval(windowMs))
        
        if now > rateData.resetTime {
            rateData = (count: 0, resetTime: now.addingTimeInterval(windowMs))
        }
        
        if rateData.count >= limit {
            return false // Rate limit exceeded
        }
        
        rateData.count += 1
        requestCounts[key] = rateData
        return true
    }
}
```

### Two-Factor Authentication (`2fa-setup.ts`)
**Features:**
- TOTP (Time-based One-Time Password) generation
- QR code generation for authenticator apps
- Backup codes generation
- Secret key management

**iOS Implementation:**
```swift
import CryptoKit

class TwoFactorManager {
    func setupTwoFactor() async throws -> TwoFactorSetup {
        let response = try await APIClient.shared.post("/api/account/2fa/setup")
        return try JSONDecoder().decode(TwoFactorSetup.self, from: response)
    }
    
    func verifyTwoFactor(code: String) async throws -> Bool {
        let request = TwoFactorVerifyRequest(code: code)
        let response = try await APIClient.shared.post("/api/account/2fa/verify", body: request)
        let result = try JSONDecoder().decode(TwoFactorVerifyResponse.self, from: response)
        return result.success
    }
}

struct TwoFactorSetup: Codable {
    let qrCode: String
    let secret: String
    let backupCodes: [String]
}
```

## 🎛️ User Preferences System (`PreferencesContext.tsx`)

### Advanced Preferences Management
**Features:**
- Multi-unit system support (miles/km, USD/EUR/GBP/CAD/AUD)
- Timezone-aware date/time formatting
- Real-time preference updates
- Auto-save functionality
- Theme and layout preferences

**iOS Implementation:**
```swift
class PreferencesManager: ObservableObject {
    @Published var preferences = UserPreferences.default
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    
    func loadPreferences() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await APIClient.shared.get("/api/account/preferences")
            let prefs = try JSONDecoder().decode(UserPreferences.self, from: response)
            DispatchQueue.main.async {
                self.preferences = prefs
            }
        } catch {
            // Use local defaults if API fails
            loadLocalPreferences()
        }
    }
    
    func updatePreference<T>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) {
        preferences[keyPath: keyPath] = value
    }
    
    func savePreferences() async throws {
        let data = try JSONEncoder().encode(preferences)
        _ = try await APIClient.shared.put("/api/account/preferences", body: data)
        saveLocalPreferences()
    }
    
    // Formatting methods
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = preferences.currency.rawValue
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func formatDistance(_ distance: Double) -> String {
        switch preferences.distanceUnit {
        case .miles:
            return String(format: "%.1f mi", distance)
        case .kilometers:
            return String(format: "%.1f km", distance * 1.60934)
        }
    }
}
```

## 🔧 Advanced Business Logic Hooks

### Maintenance Hook (`useMaintenance.ts`)
**Features:**
- Complex maintenance scheduling
- Status management workflow
- Bulk operations
- Real-time updates
- Conflict resolution

**iOS Implementation:**
```swift
class MaintenanceManager: ObservableObject {
    @Published var maintenanceRecords: [Maintenance] = []
    @Published var isLoading = false
    
    func loadMaintenance(for vehicleId: String, type: MaintenanceType? = nil, status: MaintenanceStatus? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        var components = URLComponents(string: "/api/vehicles/\(vehicleId)/maintenance")!
        var queryItems: [URLQueryItem] = []
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        do {
            let response = try await APIClient.shared.get(components.url!.absoluteString)
            let records = try JSONDecoder().decode([Maintenance].self, from: response)
            DispatchQueue.main.async {
                self.maintenanceRecords = records
            }
        } catch {
            print("Failed to load maintenance: \(error)")
        }
    }
    
    func updateMaintenanceStatus(_ maintenanceId: String, to status: MaintenanceStatus) async throws {
        let request = MaintenanceStatusUpdate(status: status)
        let data = try JSONEncoder().encode(request)
        _ = try await APIClient.shared.patch("/api/maintenance/\(maintenanceId)", body: data)
        
        // Update local state
        if let index = maintenanceRecords.firstIndex(where: { $0.id == maintenanceId }) {
            maintenanceRecords[index].status = status
        }
    }
}
```

## 📁 File Upload System (`upload.ts`)

### Advanced File Handling
**Features:**
- Multi-format support (images, PDFs, text)
- File size validation (10MB limit)
- Secure file storage
- UUID-based naming
- MIME type validation

**iOS Implementation:**
```swift
class FileUploadManager {
    func uploadFile(_ data: Data, mimeType: String, originalName: String) async throws -> UploadResponse {
        guard isValidFileType(mimeType) else {
            throw UploadError.invalidFileType
        }
        
        guard data.count <= 10 * 1024 * 1024 else {
            throw UploadError.fileTooLarge
        }
        
        let boundary = UUID().uuidString
        var body = Data()
        
        // Create multipart form data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(originalName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: URL(string: "\(APIClient.baseURL)/api/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UploadResponse.self, from: responseData)
    }
    
    private func isValidFileType(_ mimeType: String) -> Bool {
        let allowedTypes = [
            "image/jpeg", "image/jpg", "image/png", "image/webp", "image/heic",
            "application/pdf", "text/plain"
        ]
        return allowedTypes.contains(mimeType)
    }
}
```

## 📱 iOS-Specific Enhancements to Implement

### Native iOS Features
1. **Core Data Integration** for offline support
2. **CloudKit Sync** for iCloud backup
3. **Shortcuts Integration** for Siri commands
4. **Car Integration** for automatic mileage tracking
5. **Camera Integration** for receipt scanning
6. **Touch ID/Face ID** for secure authentication
7. **Today Widget** for quick expense entry
8. **Apple Pay** integration for payments

### Advanced iOS Architecture
```swift
// MVVM + Combine Architecture
class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let vehicleService: VehicleService
    private var cancellables = Set<AnyCancellable>()
    
    init(vehicleService: VehicleService = VehicleService()) {
        self.vehicleService = vehicleService
        loadVehicles()
    }
    
    private func loadVehicles() {
        isLoading = true
        
        vehicleService.fetchVehicles()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                },
                receiveValue: { vehicles in
                    self.vehicles = vehicles
                }
            )
            .store(in: &cancellables)
    }
}
```

This comprehensive guide ensures your iOS app will have all the advanced features and business logic from your sophisticated RevRegistry web application. 
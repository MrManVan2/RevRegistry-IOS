# RevRegistry iOS Integration Files

This folder contains all the essential files you need to build an iOS app that integrates with the RevRegistry backend API.

## 📁 Folder Structure

```
ios-shared/
├── database/
│   └── schema.prisma          # Database schema and data models
├── schemas/
│   └── *.ts                   # Zod validation schemas for API requests
├── types/
│   └── *.ts                   # TypeScript type definitions
├── api-examples/
│   ├── vehicles.ts            # Vehicle API endpoints
│   ├── expenses.ts            # Expense API endpoints
│   ├── maintenance.ts         # Maintenance API endpoints
│   └── auth.ts                # Authentication endpoints
├── env.example                # Environment variables example
└── README.md                  # This file
```

## 🚀 Quick Start for iOS Development

### 1. Backend Setup
Your Next.js backend should be running on `http://localhost:3000` (or your production URL).

### 2. API Base URL
```swift
let baseURL = "http://localhost:3000/api" // Development
// let baseURL = "https://yourdomain.com/api" // Production
```

### 3. Key API Endpoints

#### Authentication
- `POST /api/auth/signin` - Sign in user
- `POST /api/auth/signup` - Register new user
- `GET /api/auth/session` - Get current session

#### Vehicles
- `GET /api/vehicles` - Get user's vehicles
- `POST /api/vehicles` - Create new vehicle
- `GET /api/vehicles/[id]` - Get specific vehicle
- `PUT /api/vehicles/[id]` - Update vehicle
- `DELETE /api/vehicles/[id]` - Delete vehicle

#### Expenses
- `GET /api/expenses` - Get user's expenses
- `POST /api/expenses` - Create new expense
- `GET /api/expenses/[id]` - Get specific expense
- `PUT /api/expenses/[id]` - Update expense
- `DELETE /api/expenses/[id]` - Delete expense

#### Maintenance
- `GET /api/maintenance` - Get maintenance records
- `POST /api/maintenance` - Create maintenance record
- `GET /api/maintenance/[id]` - Get specific maintenance
- `PUT /api/maintenance/[id]` - Update maintenance
- `DELETE /api/maintenance/[id]` - Delete maintenance

## 📱 iOS Implementation Guide

### 1. Data Models
Convert the Prisma schema models to Swift structs:

```swift
struct Vehicle: Codable, Identifiable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let vin: String?
    let licensePlate: String?
    let mileage: Int
    let status: VehicleStatus
    let imageUrl: String?
    let createdAt: Date
    let updatedAt: Date
}

enum VehicleStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case maintenance = "MAINTENANCE"
    case sold = "SOLD"
    case scrapped = "SCRAPPED"
}
```

### 2. API Client Example
```swift
class APIClient: ObservableObject {
    private let baseURL = "http://localhost:3000/api"
    private let session = URLSession.shared
    
    func getVehicles() async throws -> [Vehicle] {
        guard let url = URL(string: "\(baseURL)/vehicles") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([Vehicle].self, from: data)
    }
}
```

### 3. Authentication Flow
The backend uses NextAuth with Google OAuth. For iOS, you have options:
1. **Web-based OAuth**: Use ASWebAuthenticationSession
2. **Native Google Sign-In**: Use Google Sign-In iOS SDK
3. **Custom JWT**: Implement custom JWT authentication

### 4. Required Dependencies
Add these to your iOS project:
- `Alamofire` or native `URLSession` for networking
- `SwiftUI` for UI (recommended) or `UIKit`
- `Combine` for reactive programming
- `KeychainSwift` for secure token storage

## 🔑 Environment Variables

Create a `Config.swift` file with your environment variables:

```swift
struct Config {
    static let apiBaseURL = "http://localhost:3000/api"
    static let googleClientID = "your-google-client-id"
    // Add other config values as needed
}
```

## 📋 Data Models Reference

### Core Models from Prisma Schema:
- **User**: User account information
- **Vehicle**: Vehicle details and metadata
- **Expense**: Financial transactions and costs
- **Maintenance**: Maintenance records and schedules
- **FuelEntry**: Fuel consumption tracking
- **Receipt**: Receipt image and data storage

### Enums:
- `VehicleStatus`: ACTIVE, INACTIVE, MAINTENANCE, SOLD, SCRAPPED
- `ExpenseType`: FUEL, MAINTENANCE, REPAIR, INSURANCE, etc.
- `MaintenanceType`: OIL_CHANGE, TIRE_ROTATION, BRAKE_SERVICE, etc.
- `MaintenanceStatus`: UPCOMING, DUE, OVERDUE, COMPLETED, etc.

## 🔐 Security Notes

1. **Authentication**: All API endpoints require valid session/token
2. **User Isolation**: APIs automatically filter data by authenticated user
3. **HTTPS**: Use HTTPS in production
4. **Token Storage**: Store auth tokens securely in Keychain

## 🐛 Error Handling

The API returns standard HTTP status codes:
- `200`: Success
- `401`: Unauthorized (invalid/missing auth)
- `404`: Resource not found
- `422`: Validation error
- `500`: Server error

Example error response:
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "make",
      "message": "Make is required"
    }
  ]
}
```

## 📞 Support

For questions about the API or integration, refer to the original RevRegistry repository or contact the development team. 
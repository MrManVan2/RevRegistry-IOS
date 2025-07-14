import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let image: String?
    let emailVerified: Date?
    let isActive: Bool
    let preferences: String?
    let twoFactorEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Vehicle Model
struct Vehicle: Codable, Identifiable {
    let id: String
    let userId: String
    let make: String
    let model: String
    let year: Int
    let vin: String?
    let licensePlate: String?
    let mileage: Int
    let notes: String?
    let status: VehicleStatus
    let imageUrl: String?
    let purchaseDate: Date?
    let purchasePrice: Double?
    let createdAt: Date
    let updatedAt: Date
    
    // Optional relationships
    let expenses: [Expense]?
    let maintenance: [Maintenance]?
    let fuelEntries: [FuelEntry]?
    
    // Computed counts
    struct Count: Codable {
        let expenses: Int
        let maintenance: Int
    }
    let _count: Count?
}

enum VehicleStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case maintenance = "MAINTENANCE"
    case sold = "SOLD"
    case scrapped = "SCRAPPED"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .maintenance: return "In Maintenance"
        case .sold: return "Sold"
        case .scrapped: return "Scrapped"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .inactive: return "gray"
        case .maintenance: return "orange"
        case .sold: return "blue"
        case .scrapped: return "red"
        }
    }
}

// MARK: - Expense Model
struct Expense: Codable, Identifiable {
    let id: String
    let userId: String
    let vehicleId: String
    let date: Date
    let amount: Double
    let description: String?
    let type: ExpenseType
    let category: ExpenseCategory
    let notes: String?
    let mileage: Int
    let createdAt: Date
    let updatedAt: Date
    
    // Optional relationships
    let vehicle: Vehicle?
    let receipt: Receipt?
}

enum ExpenseType: String, Codable, CaseIterable {
    case fuel = "FUEL"
    case maintenance = "MAINTENANCE"
    case repair = "REPAIR"
    case insurance = "INSURANCE"
    case registration = "REGISTRATION"
    case service = "SERVICE"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .fuel: return "Fuel"
        case .maintenance: return "Maintenance"
        case .repair: return "Repair"
        case .insurance: return "Insurance"
        case .registration: return "Registration"
        case .service: return "Service"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.fill"
        case .repair: return "hammer.fill"
        case .insurance: return "shield.fill"
        case .registration: return "doc.text.fill"
        case .service: return "gearshape.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case routine = "ROUTINE"
    case emergency = "EMERGENCY"
    case upgrade = "UPGRADE"
    case legal = "LEGAL"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .routine: return "Routine"
        case .emergency: return "Emergency"
        case .upgrade: return "Upgrade"
        case .legal: return "Legal"
        case .other: return "Other"
        }
    }
}

// MARK: - Maintenance Model
struct Maintenance: Codable, Identifiable {
    let id: String
    let userId: String
    let vehicleId: String
    let type: MaintenanceType
    let status: MaintenanceStatus
    let date: Date
    let mileage: Int
    let dueMileage: Int
    let description: String?
    let notes: String?
    let cost: Double?
    let priority: Priority
    let serviceProvider: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Optional relationships
    let vehicle: Vehicle?
    let parts: [Part]?
}

enum MaintenanceType: String, Codable, CaseIterable {
    case oilChange = "OIL_CHANGE"
    case tireRotation = "TIRE_ROTATION"
    case brakeService = "BRAKE_SERVICE"
    case inspection = "INSPECTION"
    case fluidService = "FLUID_SERVICE"
    case filterChange = "FILTER_CHANGE"
    case batteryService = "BATTERY_SERVICE"
    case transmissionService = "TRANSMISSION_SERVICE"
    case engineService = "ENGINE_SERVICE"
    case electricalService = "ELECTRICAL_SERVICE"
    case acService = "AC_SERVICE"
    case exhaustService = "EXHAUST_SERVICE"
    case suspensionService = "SUSPENSION_SERVICE"
    case wheelAlignment = "WHEEL_ALIGNMENT"
    case scheduledMaintenance = "SCHEDULED_MAINTENANCE"
    case repair = "REPAIR"
    case recall = "RECALL"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .oilChange: return "Oil Change"
        case .tireRotation: return "Tire Rotation"
        case .brakeService: return "Brake Service"
        case .inspection: return "Inspection"
        case .fluidService: return "Fluid Service"
        case .filterChange: return "Filter Change"
        case .batteryService: return "Battery Service"
        case .transmissionService: return "Transmission Service"
        case .engineService: return "Engine Service"
        case .electricalService: return "Electrical Service"
        case .acService: return "A/C Service"
        case .exhaustService: return "Exhaust Service"
        case .suspensionService: return "Suspension Service"
        case .wheelAlignment: return "Wheel Alignment"
        case .scheduledMaintenance: return "Scheduled Maintenance"
        case .repair: return "Repair"
        case .recall: return "Recall"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .tireRotation: return "circle.circle.fill"
        case .brakeService: return "stop.circle.fill"
        case .inspection: return "checkmark.seal.fill"
        case .fluidService: return "drop.degreesign.fill"
        case .filterChange: return "air.purifier.fill"
        case .batteryService: return "battery.100.bolt"
        case .transmissionService: return "gearshape.2.fill"
        case .engineService: return "engine.combustion.fill"
        case .electricalService: return "bolt.fill"
        case .acService: return "snowflake"
        case .exhaustService: return "cloud.fill"
        case .suspensionService: return "car.side.front.open"
        case .wheelAlignment: return "steering.wheel"
        case .scheduledMaintenance: return "calendar.badge.clock"
        case .repair: return "wrench.and.screwdriver.fill"
        case .recall: return "exclamationmark.triangle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum MaintenanceStatus: String, Codable, CaseIterable {
    case upcoming = "UPCOMING"
    case due = "DUE"
    case overdue = "OVERDUE"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case skipped = "SKIPPED"
    case cancelled = "CANCELLED"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .due: return "Due"
        case .overdue: return "Overdue"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .upcoming: return "blue"
        case .due: return "orange"
        case .overdue: return "red"
        case .inProgress: return "yellow"
        case .completed: return "green"
        case .skipped: return "gray"
        case .cancelled: return "gray"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Supporting Models
struct Receipt: Codable, Identifiable {
    let id: String
    let expenseId: String
    let imageUrl: String
    let ocrText: String?
    let createdAt: Date
    let updatedAt: Date
}

struct Part: Codable, Identifiable {
    let id: String
    let maintenanceId: String
    let name: String
    let partNumber: String?
    let cost: Double
    let quantity: Int
    let supplier: String?
    let createdAt: Date
    let updatedAt: Date
}

struct FuelEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let vehicleId: String
    let date: Date
    let mileage: Int
    let gallons: Double
    let pricePerGallon: Double
    let totalCost: Double
    let fuelType: FuelType
    let location: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Optional relationships
    let vehicle: Vehicle?
}

enum FuelType: String, Codable, CaseIterable {
    case regular = "REGULAR"
    case premium = "PREMIUM"
    case diesel = "DIESEL"
    case electric = "ELECTRIC"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .premium: return "Premium"
        case .diesel: return "Diesel"
        case .electric: return "Electric"
        case .other: return "Other"
        }
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
    let message: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let total: Int
    let page: Int
    let limit: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let user: User
    let token: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

// MARK: - Email Verification Models
struct RegisterResponse: Codable {
    let message: String
    let email: String
    let requiresVerification: Bool
}

struct VerifyEmailRequest: Codable {
    let email: String
    let verificationCode: String
}

struct VerifyEmailResponse: Codable {
    let user: User
    let token: String
    let message: String
}

struct ResendVerificationRequest: Codable {
    let email: String
}

struct ResendVerificationResponse: Codable {
    let message: String
}

// MARK: - Business Logic Models
struct ExpenseAnalysis: Codable {
    let totalByCategory: [String: Double]
    let monthlyTrends: [MonthlyExpense]
    let costPerMile: Double
    let projectedAnnualCost: Double
}

struct MonthlyExpense: Codable {
    let month: String
    let total: Double
    let count: Int
}

struct MaintenanceSchedule: Codable {
    let upcoming: [Maintenance]
    let overdue: [Maintenance]
    let recommendations: [MaintenanceRecommendation]
}

struct MaintenanceRecommendation: Codable {
    let type: MaintenanceType
    let priority: Priority
    let estimatedCost: Double
    let dueMileage: Int
    let description: String
} 
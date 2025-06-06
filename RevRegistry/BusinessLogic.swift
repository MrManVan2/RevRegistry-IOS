import Foundation

// MARK: - Vehicle Business Logic
class VehicleBusinessLogic {
    
    // MARK: - Depreciation Calculations
    
    static func calculateDepreciation(for vehicle: Vehicle) -> Double {
        guard let purchaseDate = vehicle.purchaseDate,
              let purchasePrice = vehicle.purchasePrice else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let yearsOwned = calendar.dateComponents([.year], from: purchaseDate, to: Date()).year ?? 0
        let standardDepreciation = 0.15 // 15% per year
        
        // Calculate time-based depreciation
        let timeDepreciation = purchasePrice * (1 - pow(1 - standardDepreciation, Double(yearsOwned)))
        
        // Calculate mileage-based depreciation (assuming initial mileage was 0 for simplicity)
        let mileageDepreciation = Double(vehicle.mileage) * 0.10 // $0.10 per mile
        
        return timeDepreciation + mileageDepreciation
    }
    
    static func calculateCurrentValue(for vehicle: Vehicle) -> Double {
        guard let purchasePrice = vehicle.purchasePrice else { return 0.0 }
        let depreciation = calculateDepreciation(for: vehicle)
        return max(0, purchasePrice - depreciation)
    }
    
    static func calculateDepreciationRate(for vehicle: Vehicle) -> Double {
        guard let purchasePrice = vehicle.purchasePrice, purchasePrice > 0 else { return 0.0 }
        let depreciation = calculateDepreciation(for: vehicle)
        return (depreciation / purchasePrice) * 100
    }
    
    // MARK: - Maintenance Scheduling
    
    static func shouldScheduleMaintenance(for vehicle: Vehicle, maintenanceType: MaintenanceType, lastMaintenance: Maintenance?) -> Bool {
        let mileageSinceLast = vehicle.mileage - (lastMaintenance?.mileage ?? 0)
        
        switch maintenanceType {
        case .oilChange:
            return mileageSinceLast >= 4500 // Due every 5000 miles, warn at 4500
        case .tireRotation:
            return mileageSinceLast >= 7000 // Due every 7500 miles, warn at 7000
        case .brakeService:
            return mileageSinceLast >= 24000 // Due every 25000 miles
        case .inspection:
            // Annual inspection
            if let lastDate = lastMaintenance?.date {
                let monthsSince = Calendar.current.dateComponents([.month], from: lastDate, to: Date()).month ?? 0
                return monthsSince >= 11
            }
            return true
        case .fluidService:
            return mileageSinceLast >= 29000 // Due every 30000 miles
        case .filterChange:
            return mileageSinceLast >= 14000 // Due every 15000 miles
        case .batteryService:
            // Every 3 years or based on age
            if let lastDate = lastMaintenance?.date {
                let yearsSince = Calendar.current.dateComponents([.year], from: lastDate, to: Date()).year ?? 0
                return yearsSince >= 3
            }
            return true
        default:
            return false
        }
    }
    
    static func getMaintenanceInterval(for type: MaintenanceType) -> Int {
        switch type {
        case .oilChange: return 5000
        case .tireRotation: return 7500
        case .brakeService: return 25000
        case .inspection: return 12000 // Approximate miles per year
        case .fluidService: return 30000
        case .filterChange: return 15000
        case .batteryService: return 36000 // 3 years * 12k miles/year
        case .transmissionService: return 60000
        case .engineService: return 100000
        case .wheelAlignment: return 20000
        default: return 10000
        }
    }
}

// MARK: - Expense Business Logic
class ExpenseBusinessLogic {
    
    // MARK: - Expense Analysis
    
    static func analyzeExpenses(_ expenses: [Expense], for vehicle: Vehicle) -> ExpenseAnalysis {
        let totalByCategory = Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        let monthlyTrends = calculateMonthlyTrends(expenses)
        let totalCost = expenses.reduce(0) { $0 + $1.amount }
        let costPerMile = vehicle.mileage > 0 ? totalCost / Double(vehicle.mileage) : 0
        
        return ExpenseAnalysis(
            totalByCategory: totalByCategory.mapKeys { $0.rawValue },
            monthlyTrends: monthlyTrends,
            costPerMile: costPerMile,
            projectedAnnualCost: calculateProjectedAnnualCost(expenses)
        )
    }
    
    static func calculateMonthlyTrends(_ expenses: [Expense]) -> [MonthlyExpense] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        let monthlyGroups = Dictionary(grouping: expenses) { expense in
            formatter.string(from: expense.date)
        }
        
        return monthlyGroups.map { month, expenses in
            MonthlyExpense(
                month: month,
                total: expenses.reduce(0) { $0 + $1.amount },
                count: expenses.count
            )
        }.sorted { $0.month < $1.month }
    }
    
    static func calculateProjectedAnnualCost(_ expenses: [Expense]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        
        let recentExpenses = expenses.filter { $0.date >= oneYearAgo }
        let totalRecent = recentExpenses.reduce(0) { $0 + $1.amount }
        
        let daysCovered = calendar.dateComponents([.day], from: oneYearAgo, to: now).day ?? 365
        let dailyAverage = totalRecent / Double(daysCovered)
        
        return dailyAverage * 365
    }
    
    static func calculateCostPerMile(_ expenses: [Expense], totalMileage: Int) -> Double {
        let totalCost = expenses.reduce(0) { $0 + $1.amount }
        return totalMileage > 0 ? totalCost / Double(totalMileage) : 0
    }
    
    // MARK: - Smart Categorization
    
    static func categorizeExpenseAutomatically(description: String, amount: Double) -> (ExpenseType, ExpenseCategory) {
        let lowercased = description.lowercased()
        
        // Fuel detection
        if lowercased.contains("gas") || lowercased.contains("fuel") || 
           lowercased.contains("shell") || lowercased.contains("exxon") ||
           lowercased.contains("bp") || lowercased.contains("chevron") ||
           lowercased.contains("mobil") || lowercased.contains("texaco") {
            return (.fuel, .routine)
        }
        
        // Maintenance detection
        if lowercased.contains("oil") || lowercased.contains("tire") || 
           lowercased.contains("brake") || lowercased.contains("filter") ||
           lowercased.contains("tune") || lowercased.contains("service") {
            return (.maintenance, amount > 500 ? .emergency : .routine)
        }
        
        // Insurance detection
        if lowercased.contains("insurance") || lowercased.contains("policy") ||
           lowercased.contains("premium") || lowercased.contains("geico") ||
           lowercased.contains("state farm") || lowercased.contains("allstate") {
            return (.insurance, .legal)
        }
        
        // Registration detection
        if lowercased.contains("registration") || lowercased.contains("dmv") ||
           lowercased.contains("license") || lowercased.contains("tag") ||
           lowercased.contains("renewal") {
            return (.registration, .legal)
        }
        
        // Repair detection
        if lowercased.contains("repair") || lowercased.contains("fix") ||
           lowercased.contains("replace") || lowercased.contains("broken") {
            return (.repair, amount > 1000 ? .emergency : .routine)
        }
        
        // Service detection
        if lowercased.contains("wash") || lowercased.contains("detail") ||
           lowercased.contains("clean") {
            return (.service, .routine)
        }
        
        return (.other, .other)
    }
    
    // MARK: - Expense Predictions
    
    static func predictNextExpense(for vehicle: Vehicle, expenses: [Expense]) -> Date? {
        let fuelExpenses = expenses.filter { $0.type == .fuel }.sorted { $0.date > $1.date }
        
        guard fuelExpenses.count >= 2 else { return nil }
        
        let lastTwo = Array(fuelExpenses.prefix(2))
        let daysBetween = Calendar.current.dateComponents([.day], 
                                                         from: lastTwo[1].date, 
                                                         to: lastTwo[0].date).day ?? 7
        
        return Calendar.current.date(byAdding: .day, value: daysBetween, to: lastTwo[0].date)
    }
}

// MARK: - Maintenance Business Logic
class MaintenanceBusinessLogic {
    
    // MARK: - Maintenance Scheduling
    
    static func generateMaintenanceSchedule(for vehicle: Vehicle, history: [Maintenance]) -> MaintenanceSchedule {
        var recommendations: [MaintenanceRecommendation] = []
        
        // Oil change logic
        let lastOilChange = history
            .filter { $0.type == .oilChange && $0.status == .completed }
            .max { $0.mileage < $1.mileage }
        
        let mileageSinceOilChange = vehicle.mileage - (lastOilChange?.mileage ?? 0)
        if mileageSinceOilChange > 4500 {
            let priority: Priority = mileageSinceOilChange > 5500 ? .high : .medium
            recommendations.append(MaintenanceRecommendation(
                type: .oilChange,
                priority: priority,
                estimatedCost: 75.0,
                dueMileage: (lastOilChange?.mileage ?? 0) + 5000,
                description: "Oil change is due every 5,000 miles"
            ))
        }
        
        // Tire rotation logic
        let lastTireRotation = history
            .filter { $0.type == .tireRotation && $0.status == .completed }
            .max { $0.mileage < $1.mileage }
        
        let mileageSinceTireRotation = vehicle.mileage - (lastTireRotation?.mileage ?? 0)
        if mileageSinceTireRotation > 7000 {
            recommendations.append(MaintenanceRecommendation(
                type: .tireRotation,
                priority: .medium,
                estimatedCost: 50.0,
                dueMileage: (lastTireRotation?.mileage ?? 0) + 7500,
                description: "Tire rotation is recommended every 7,500 miles"
            ))
        }
        
        // Brake service logic
        let lastBrakeService = history
            .filter { $0.type == .brakeService && $0.status == .completed }
            .max { $0.mileage < $1.mileage }
        
        let mileageSinceBrakeService = vehicle.mileage - (lastBrakeService?.mileage ?? 0)
        if mileageSinceBrakeService > 24000 {
            let priority: Priority = mileageSinceBrakeService > 30000 ? .high : .medium
            recommendations.append(MaintenanceRecommendation(
                type: .brakeService,
                priority: priority,
                estimatedCost: 300.0,
                dueMileage: (lastBrakeService?.mileage ?? 0) + 25000,
                description: "Brake service is recommended every 25,000 miles"
            ))
        }
        
        // Filter upcoming and overdue from existing maintenance
        let upcoming = history.filter { $0.status == .upcoming && $0.date > Date() }
        let overdue = history.filter { 
            $0.status == .due || $0.status == .overdue || 
            ($0.status == .upcoming && $0.date <= Date())
        }
        
        return MaintenanceSchedule(
            upcoming: upcoming,
            overdue: overdue,
            recommendations: recommendations
        )
    }
    
    static func calculateMaintenanceCost(for vehicle: Vehicle, maintenance: [Maintenance]) -> Double {
        return maintenance.compactMap { $0.cost }.reduce(0, +)
    }
    
    static func getMaintenanceEfficiency(for vehicle: Vehicle, maintenance: [Maintenance]) -> Double {
        let completedMaintenance = maintenance.filter { $0.status == .completed }
        let totalMaintenance = maintenance.count
        
        return totalMaintenance > 0 ? Double(completedMaintenance.count) / Double(totalMaintenance) : 0
    }
    
    // MARK: - Maintenance Predictions
    
    static func predictNextMaintenance(for vehicle: Vehicle, type: MaintenanceType, history: [Maintenance]) -> Date? {
        let typeHistory = history.filter { $0.type == type && $0.status == .completed }
            .sorted { $0.date > $1.date }
        
        guard let lastMaintenance = typeHistory.first else {
            // If no history, predict based on current mileage and intervals
            let interval = VehicleBusinessLogic.getMaintenanceInterval(for: type)
            let milesUntilDue = interval - (vehicle.mileage % interval)
            let averageMilesPerDay = 33 // Approximate 12k miles per year
            let daysUntilDue = milesUntilDue / averageMilesPerDay
            
            return Calendar.current.date(byAdding: .day, value: daysUntilDue, to: Date())
        }
        
        let interval = VehicleBusinessLogic.getMaintenanceInterval(for: type)
        let mileageSinceLast = vehicle.mileage - lastMaintenance.mileage
        let milesUntilDue = interval - mileageSinceLast
        
        if milesUntilDue <= 0 {
            return Date() // Overdue
        }
        
        let averageMilesPerDay = 33
        let daysUntilDue = milesUntilDue / averageMilesPerDay
        
        return Calendar.current.date(byAdding: .day, value: daysUntilDue, to: Date())
    }
}

// MARK: - Analytics Business Logic
class AnalyticsBusinessLogic {
    
    // MARK: - Cost Analysis
    
    static func calculateTotalCostOfOwnership(for vehicle: Vehicle, expenses: [Expense], maintenance: [Maintenance]) -> Double {
        let expenseCost = expenses.reduce(0) { $0 + $1.amount }
        let maintenanceCost = maintenance.compactMap { $0.cost }.reduce(0, +)
        let purchasePrice = vehicle.purchasePrice ?? 0
        
        return purchasePrice + expenseCost + maintenanceCost
    }
    
    static func calculateCostPerMileOwnership(for vehicle: Vehicle, expenses: [Expense], maintenance: [Maintenance]) -> Double {
        let totalCost = calculateTotalCostOfOwnership(for: vehicle, expenses: expenses, maintenance: maintenance)
        return vehicle.mileage > 0 ? totalCost / Double(vehicle.mileage) : 0
    }
    
    static func calculateMonthlyAverageCost(expenses: [Expense], maintenance: [Maintenance]) -> Double {
        let allCosts = expenses.map { $0.amount } + maintenance.compactMap { $0.cost }
        let totalCost = allCosts.reduce(0, +)
        
        // Calculate months of ownership
        let allDates = expenses.map { $0.date } + maintenance.map { $0.date }
        guard let earliestDate = allDates.min(),
              let latestDate = allDates.max() else {
            return 0
        }
        
        let months = Calendar.current.dateComponents([.month], from: earliestDate, to: latestDate).month ?? 1
        return totalCost / Double(max(1, months))
    }
    
    // MARK: - Efficiency Metrics
    
    static func calculateFuelEfficiency(expenses: [Expense]) -> Double {
        let fuelExpenses = expenses.filter { $0.type == .fuel }
        guard !fuelExpenses.isEmpty else { return 0 }
        
        let totalFuelCost = fuelExpenses.reduce(0) { $0 + $1.amount }
        let averageFuelPrice = 3.50 // Approximate price per gallon
        let totalGallons = totalFuelCost / averageFuelPrice
        
        // Estimate miles driven (this would be more accurate with actual fuel entry data)
        let milesDriven = fuelExpenses.count * 300 // Rough estimate
        
        return totalGallons > 0 ? Double(milesDriven) / totalGallons : 0
    }
}

// MARK: - Helper Extensions
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}
# RevRegistry Business Logic Implementation Guide

This document details all the complex business logic, calculations, and workflows from the RevRegistry web app.

## 🚗 Vehicle Management Logic

### Vehicle Lifecycle Management
```typescript
// From use-vehicles.ts
interface VehicleLifecycle {
  purchaseDate: Date
  purchasePrice: number
  currentMileage: number
  status: VehicleStatus
  depreciationRate: number
}

// Depreciation calculation
function calculateDepreciation(vehicle: Vehicle): number {
  const yearsOwned = (Date.now() - vehicle.purchaseDate.getTime()) / (1000 * 60 * 60 * 24 * 365)
  const standardDepreciation = 0.15 // 15% per year
  const mileageDepreciation = (vehicle.mileage - vehicle.initialMileage) * 0.10 // $0.10 per mile
  
  return vehicle.purchasePrice * (1 - Math.pow(1 - standardDepreciation, yearsOwned)) + mileageDepreciation
}
```

**iOS Implementation:**
```swift
class VehicleBusinessLogic {
    static func calculateDepreciation(for vehicle: Vehicle) -> Double {
        let calendar = Calendar.current
        let yearsOwned = calendar.dateComponents([.year], from: vehicle.purchaseDate ?? Date(), to: Date()).year ?? 0
        let standardDepreciation = 0.15 // 15% per year
        let mileageDepreciation = Double(vehicle.mileage - (vehicle.initialMileage ?? 0)) * 0.10
        
        let timeDepreciation = (vehicle.purchasePrice ?? 0) * (1 - pow(1 - standardDepreciation, Double(yearsOwned)))
        return timeDepreciation + mileageDepreciation
    }
    
    static func calculateCurrentValue(for vehicle: Vehicle) -> Double {
        let depreciation = calculateDepreciation(for: vehicle)
        return max(0, (vehicle.purchasePrice ?? 0) - depreciation)
    }
    
    static func shouldScheduleMaintenance(for vehicle: Vehicle, maintenanceType: MaintenanceType) -> Bool {
        switch maintenanceType {
        case .oilChange:
            return vehicle.mileage % 5000 < 500 // Due every 5000 miles, warn at 4500
        case .tireRotation:
            return vehicle.mileage % 7500 < 500 // Due every 7500 miles
        case .inspection:
            let calendar = Calendar.current
            let monthsSinceLastInspection = calendar.dateComponents([.month], from: vehicle.lastInspection ?? Date(), to: Date()).month ?? 0
            return monthsSinceLastInspection >= 11 // Annual inspection
        default:
            return false
        }
    }
}
```

## 💰 Expense Management Logic

### Expense Categorization & Analysis
```typescript
// Advanced expense analysis from useFormatting.ts
interface ExpenseAnalysis {
  totalByCategory: Record<ExpenseCategory, number>
  monthlyTrends: MonthlyExpense[]
  costPerMile: number
  projectedAnnualCost: number
}

function analyzeExpenses(expenses: Expense[], vehicle: Vehicle): ExpenseAnalysis {
  const totalByCategory = expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + expense.amount
    return acc
  }, {} as Record<ExpenseCategory, number>)

  const monthlyTrends = calculateMonthlyTrends(expenses)
  const totalCost = expenses.reduce((sum, exp) => sum + exp.amount, 0)
  const costPerMile = totalCost / vehicle.mileage
  
  return {
    totalByCategory,
    monthlyTrends,
    costPerMile,
    projectedAnnualCost: calculateProjectedAnnualCost(expenses)
  }
}
```

**iOS Implementation:**
```swift
class ExpenseBusinessLogic {
    static func analyzeExpenses(_ expenses: [Expense], for vehicle: Vehicle) -> ExpenseAnalysis {
        let totalByCategory = Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        let monthlyTrends = calculateMonthlyTrends(expenses)
        let totalCost = expenses.reduce(0) { $0 + $1.amount }
        let costPerMile = vehicle.mileage > 0 ? totalCost / Double(vehicle.mileage) : 0
        
        return ExpenseAnalysis(
            totalByCategory: totalByCategory,
            monthlyTrends: monthlyTrends,
            costPerMile: costPerMile,
            projectedAnnualCost: calculateProjectedAnnualCost(expenses)
        )
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
    
    static func categorizeExpenseAutomatically(description: String, amount: Double) -> (ExpenseType, ExpenseCategory) {
        let lowercased = description.lowercased()
        
        // Fuel detection
        if lowercased.contains("gas") || lowercased.contains("fuel") || lowercased.contains("shell") || lowercased.contains("exxon") {
            return (.fuel, .routine)
        }
        
        // Maintenance detection
        if lowercased.contains("oil") || lowercased.contains("tire") || lowercased.contains("brake") {
            return (.maintenance, amount > 500 ? .emergency : .routine)
        }
        
        // Insurance detection
        if lowercased.contains("insurance") || lowercased.contains("policy") {
            return (.insurance, .legal)
        }
        
        return (.other, .other)
    }
}
```

## 🔧 Maintenance Scheduling Logic

### Advanced Maintenance Algorithms
```typescript
// From useMaintenance.ts - Complex scheduling logic
interface MaintenanceSchedule {
  upcoming: Maintenance[]
  overdue: Maintenance[]
  recommendations: MaintenanceRecommendation[]
}

function generateMaintenanceSchedule(vehicle: Vehicle, history: Maintenance[]): MaintenanceSchedule {
  const recommendations = []
  
  // Oil change logic
  const lastOilChange = history
    .filter(m => m.type === 'OIL_CHANGE' && m.status === 'COMPLETED')
    .sort((a, b) => b.mileage - a.mileage)[0]
  
  if (!lastOilChange || (vehicle.mileage - lastOilChange.mileage) > 4500) {
    recommendations.push({
      type: 'OIL_CHANGE',
      priority: vehicle.mileage - (lastOilChange?.mileage || 0) > 5500 ? 'HIGH' : 'MEDIUM',
      estimatedCost: 75,
      dueMileage: (lastOilChange?.mileage || 0) + 5000
    })
  }
  
  return {
    upcoming: getUpcomingMaintenance(recommendations),
    overdue: getOverdueMaintenance(recommendations, vehicle),
    recommendations
  }
}
```

**iOS Implementation:**
```swift
class MaintenanceBusinessLogic {
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
                estimatedCost: 75,
                dueMileage: (lastOilChange?.mileage ?? 0) + 5000,
                description: "Regular oil change service"
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
                estimatedCost: 50,
                dueMileage: (lastTireRotation?.mileage ?? 0) + 7500,
                description: "Tire rotation for even wear"
            ))
        }
        
        // Brake inspection logic
        let lastBrakeService = history
            .filter { $0.type == .brakeService && $0.status == .completed }
            .max { $0.mileage < $1.mileage }
        
        let mileageSinceBrakeService = vehicle.mileage - (lastBrakeService?.mileage ?? 0)
        if mileageSinceBrakeService > 25000 {
            recommendations.append(MaintenanceRecommendation(
                type: .brakeService,
                priority: mileageSinceBrakeService > 30000 ? .high : .medium,
                estimatedCost: 300,
                dueMileage: (lastBrakeService?.mileage ?? 0) + 30000,
                description: "Brake pad and rotor inspection"
            ))
        }
        
        return MaintenanceSchedule(
            upcoming: getUpcomingMaintenance(recommendations, vehicle),
            overdue: getOverdueMaintenance(recommendations, vehicle),
            recommendations: recommendations
        )
    }
    
    static func calculateMaintenanceCostTrends(_ history: [Maintenance]) -> [MonthlyMaintenanceCost] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { maintenance in
            calendar.dateComponents([.year, .month], from: maintenance.date)
        }
        
        return grouped.compactMap { (dateComponents, maintenances) in
            guard let year = dateComponents.year, let month = dateComponents.month else { return nil }
            let totalCost = maintenances.compactMap { $0.cost }.reduce(0, +)
            return MonthlyMaintenanceCost(
                year: year,
                month: month,
                totalCost: totalCost,
                itemCount: maintenances.count
            )
        }.sorted { $0.year < $1.year || ($0.year == $1.year && $0.month < $1.month) }
    }
}
```

## ⛽ Fuel Efficiency Calculations

### Advanced MPG Analysis
```typescript
// Fuel efficiency calculations
interface FuelEfficiencyAnalysis {
  currentMPG: number
  averageMPG: number
  trend: 'improving' | 'declining' | 'stable'
  costPerMile: number
  projectedMonthlyCost: number
}

function calculateFuelEfficiency(fuelEntries: FuelEntry[]): FuelEfficiencyAnalysis {
  const sortedEntries = fuelEntries.sort((a, b) => a.date.getTime() - b.date.getTime())
  
  const mpgCalculations = []
  for (let i = 1; i < sortedEntries.length; i++) {
    const current = sortedEntries[i]
    const previous = sortedEntries[i - 1]
    const milesDriven = current.mileage - previous.mileage
    const mpg = milesDriven / current.gallons
    mpgCalculations.push({ mpg, date: current.date })
  }
  
  const averageMPG = mpgCalculations.reduce((sum, calc) => sum + calc.mpg, 0) / mpgCalculations.length
  const recentMPG = mpgCalculations.slice(-3).reduce((sum, calc) => sum + calc.mpg, 0) / 3
  
  return {
    currentMPG: recentMPG,
    averageMPG,
    trend: determineTrend(mpgCalculations),
    costPerMile: calculateCostPerMile(fuelEntries),
    projectedMonthlyCost: calculateProjectedMonthlyCost(fuelEntries)
  }
}
```

**iOS Implementation:**
```swift
class FuelBusinessLogic {
    static func calculateFuelEfficiency(_ fuelEntries: [FuelEntry]) -> FuelEfficiencyAnalysis {
        let sortedEntries = fuelEntries.sorted { $0.date < $1.date }
        
        var mpgCalculations: [(mpg: Double, date: Date)] = []
        
        for i in 1..<sortedEntries.count {
            let current = sortedEntries[i]
            let previous = sortedEntries[i - 1]
            let milesDriven = Double(current.mileage - previous.mileage)
            
            if current.gallons > 0 && milesDriven > 0 {
                let mpg = milesDriven / current.gallons
                mpgCalculations.append((mpg: mpg, date: current.date))
            }
        }
        
        guard !mpgCalculations.isEmpty else {
            return FuelEfficiencyAnalysis(
                currentMPG: 0,
                averageMPG: 0,
                trend: .stable,
                costPerMile: 0,
                projectedMonthlyCost: 0
            )
        }
        
        let averageMPG = mpgCalculations.reduce(0) { $0 + $1.mpg } / Double(mpgCalculations.count)
        let recentCalculations = Array(mpgCalculations.suffix(3))
        let recentMPG = recentCalculations.reduce(0) { $0 + $1.mpg } / Double(recentCalculations.count)
        
        return FuelEfficiencyAnalysis(
            currentMPG: recentMPG,
            averageMPG: averageMPG,
            trend: determineTrend(mpgCalculations),
            costPerMile: calculateCostPerMile(fuelEntries),
            projectedMonthlyCost: calculateProjectedMonthlyCost(fuelEntries)
        )
    }
    
    static func determineTrend(_ calculations: [(mpg: Double, date: Date)]) -> FuelTrend {
        guard calculations.count >= 6 else { return .stable }
        
        let firstHalf = Array(calculations.prefix(calculations.count / 2))
        let secondHalf = Array(calculations.suffix(calculations.count / 2))
        
        let firstAverage = firstHalf.reduce(0) { $0 + $1.mpg } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0) { $0 + $1.mpg } / Double(secondHalf.count)
        
        let difference = secondAverage - firstAverage
        let threshold = firstAverage * 0.05 // 5% threshold
        
        if difference > threshold {
            return .improving
        } else if difference < -threshold {
            return .declining
        } else {
            return .stable
        }
    }
    
    static func calculateOptimalFuelStops(_ fuelEntries: [FuelEntry]) -> [FuelStopRecommendation] {
        // Analyze patterns to recommend optimal fuel stops
        let averageGallons = fuelEntries.reduce(0) { $0 + $1.gallons } / Double(fuelEntries.count)
        let averagePricePerGallon = fuelEntries.reduce(0) { $0 + $1.pricePerGallon } / Double(fuelEntries.count)
        
        // Group by station to find best prices
        let stationGroups = Dictionary(grouping: fuelEntries) { $0.stationName ?? "Unknown" }
        
        return stationGroups.compactMap { (station, entries) in
            let averagePrice = entries.reduce(0) { $0 + $1.pricePerGallon } / Double(entries.count)
            let savings = (averagePricePerGallon - averagePrice) * averageGallons
            
            guard savings > 0 else { return nil }
            
            return FuelStopRecommendation(
                stationName: station,
                averagePrice: averagePrice,
                potentialSavings: savings,
                visitCount: entries.count
            )
        }.sorted { $0.potentialSavings > $1.potentialSavings }
    }
}
```

## 📊 Analytics & KPI Calculations

### Advanced Analytics Logic
```typescript
// From analytics.ts - Complex KPI calculations
interface VehicleKPIs {
  totalCostOfOwnership: number
  costPerMile: number
  monthlyOperatingCost: number
  depreciationRate: number
  maintenanceEfficiency: number
  fuelEfficiencyTrend: number
}

function calculateVehicleKPIs(vehicle: Vehicle, expenses: Expense[], maintenance: Maintenance[], fuelEntries: FuelEntry[]): VehicleKPIs {
  const totalExpenses = expenses.reduce((sum, exp) => sum + exp.amount, 0)
  const totalMaintenance = maintenance.reduce((sum, maint) => sum + (maint.cost || 0), 0)
  const totalFuel = fuelEntries.reduce((sum, fuel) => sum + fuel.totalCost, 0)
  
  const totalCostOfOwnership = (vehicle.purchasePrice || 0) + totalExpenses + totalMaintenance + totalFuel
  const costPerMile = totalCostOfOwnership / vehicle.mileage
  
  return {
    totalCostOfOwnership,
    costPerMile,
    monthlyOperatingCost: calculateMonthlyOperatingCost(expenses, maintenance, fuelEntries),
    depreciationRate: calculateDepreciationRate(vehicle),
    maintenanceEfficiency: calculateMaintenanceEfficiency(maintenance),
    fuelEfficiencyTrend: calculateFuelEfficiencyTrend(fuelEntries)
  }
}
```

**iOS Implementation:**
```swift
class AnalyticsBusinessLogic {
    static func calculateVehicleKPIs(
        vehicle: Vehicle,
        expenses: [Expense],
        maintenance: [Maintenance],
        fuelEntries: [FuelEntry]
    ) -> VehicleKPIs {
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
        let totalMaintenance = maintenance.compactMap { $0.cost }.reduce(0, +)
        let totalFuel = fuelEntries.reduce(0) { $0 + $1.totalCost }
        
        let totalCostOfOwnership = (vehicle.purchasePrice ?? 0) + totalExpenses + totalMaintenance + totalFuel
        let costPerMile = vehicle.mileage > 0 ? totalCostOfOwnership / Double(vehicle.mileage) : 0
        
        return VehicleKPIs(
            totalCostOfOwnership: totalCostOfOwnership,
            costPerMile: costPerMile,
            monthlyOperatingCost: calculateMonthlyOperatingCost(expenses, maintenance, fuelEntries),
            depreciationRate: calculateDepreciationRate(vehicle),
            maintenanceEfficiency: calculateMaintenanceEfficiency(maintenance),
            fuelEfficiencyTrend: calculateFuelEfficiencyTrend(fuelEntries)
        )
    }
    
    static func generateInsights(kpis: VehicleKPIs, vehicle: Vehicle) -> [VehicleInsight] {
        var insights: [VehicleInsight] = []
        
        // Cost per mile insight
        if kpis.costPerMile > 0.75 {
            insights.append(VehicleInsight(
                type: .warning,
                title: "High Cost Per Mile",
                description: "Your cost per mile is above average. Consider reviewing maintenance and fuel efficiency.",
                actionable: true,
                priority: .medium
            ))
        }
        
        // Maintenance efficiency insight
        if kpis.maintenanceEfficiency < 0.7 {
            insights.append(VehicleInsight(
                type: .suggestion,
                title: "Maintenance Optimization",
                description: "Regular preventive maintenance could reduce your overall costs.",
                actionable: true,
                priority: .high
            ))
        }
        
        // Fuel efficiency insight
        if kpis.fuelEfficiencyTrend < -0.1 {
            insights.append(VehicleInsight(
                type: .alert,
                title: "Declining Fuel Efficiency",
                description: "Your fuel efficiency has been declining. Consider a tune-up or tire check.",
                actionable: true,
                priority: .high
            ))
        }
        
        return insights
    }
}
```

This comprehensive business logic documentation ensures your iOS app will implement all the sophisticated calculations and workflows from your RevRegistry web application. 
import Foundation
import Combine

class MaintenanceService: ObservableObject {
    @Published var maintenance: [Maintenance] = []
    @Published var selectedMaintenance: Maintenance?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var upcomingMaintenance: [Maintenance] = []
    @Published var overdueMaintenance: [Maintenance] = []
    
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Methods
    
    func fetchMaintenance(vehicleId: String? = nil, status: MaintenanceStatus? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var queryParams: [String] = []
        if let vehicleId = vehicleId {
            queryParams.append("vehicleId=\(vehicleId)")
        }
        if let status = status {
            queryParams.append("status=\(status.rawValue)")
        }
        
        let queryString = queryParams.isEmpty ? "" : "?" + queryParams.joined(separator: "&")
        
        do {
            let maintenance: [Maintenance] = try await apiClient.get("/maintenance\(queryString)")
            await MainActor.run {
                self.maintenance = maintenance
                self.updateMaintenanceCategories()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchMaintenance(id: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let maintenance: Maintenance = try await apiClient.get("/maintenance/\(id)")
            await MainActor.run {
                self.selectedMaintenance = maintenance
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func createMaintenance(
        vehicleId: String,
        type: MaintenanceType,
        status: MaintenanceStatus = .upcoming,
        date: Date,
        mileage: Int,
        dueMileage: Int,
        description: String? = nil,
        notes: String? = nil,
        cost: Double? = nil,
        priority: Priority = .medium,
        serviceProvider: String? = nil
    ) async throws -> Maintenance {
        let maintenanceData: [String: Any] = [
            "vehicleId": vehicleId,
            "type": type.rawValue,
            "status": status.rawValue,
            "date": date.iso8601String,
            "mileage": mileage,
            "dueMileage": dueMileage,
            "description": description as Any,
            "notes": notes as Any,
            "cost": cost as Any,
            "priority": priority.rawValue,
            "serviceProvider": serviceProvider as Any
        ].compactMapValues { value in
            if case Optional<Any>.some(let unwrapped) = value {
                return unwrapped
            }
            return value is NSNull ? nil : value
        }
        
        let maintenance: Maintenance = try await apiClient.post("/maintenance", body: maintenanceData)
        
        await MainActor.run {
            self.maintenance.append(maintenance)
            self.updateMaintenanceCategories()
        }
        
        return maintenance
    }
    
    func updateMaintenance(
        id: String,
        type: MaintenanceType? = nil,
        status: MaintenanceStatus? = nil,
        date: Date? = nil,
        mileage: Int? = nil,
        dueMileage: Int? = nil,
        description: String? = nil,
        notes: String? = nil,
        cost: Double? = nil,
        priority: Priority? = nil,
        serviceProvider: String? = nil
    ) async throws -> Maintenance {
        var updateData: [String: Any] = [:]
        
        if let type = type { updateData["type"] = type.rawValue }
        if let status = status { updateData["status"] = status.rawValue }
        if let date = date { updateData["date"] = date.iso8601String }
        if let mileage = mileage { updateData["mileage"] = mileage }
        if let dueMileage = dueMileage { updateData["dueMileage"] = dueMileage }
        if let description = description { updateData["description"] = description }
        if let notes = notes { updateData["notes"] = notes }
        if let cost = cost { updateData["cost"] = cost }
        if let priority = priority { updateData["priority"] = priority.rawValue }
        if let serviceProvider = serviceProvider { updateData["serviceProvider"] = serviceProvider }
        
        let maintenance: Maintenance = try await apiClient.put("/maintenance/\(id)", body: updateData)
        
        await MainActor.run {
            if let index = self.maintenance.firstIndex(where: { $0.id == id }) {
                self.maintenance[index] = maintenance
            }
            if self.selectedMaintenance?.id == id {
                self.selectedMaintenance = maintenance
            }
            self.updateMaintenanceCategories()
        }
        
        return maintenance
    }
    
    func deleteMaintenance(id: String) async throws {
        let _: [String: String] = try await apiClient.delete("/maintenance/\(id)")
        
        await MainActor.run {
            self.maintenance.removeAll { $0.id == id }
            if self.selectedMaintenance?.id == id {
                self.selectedMaintenance = nil
            }
            self.updateMaintenanceCategories()
        }
    }
    
    func completeMaintenance(id: String, cost: Double? = nil, notes: String? = nil) async throws {
        var updateData: [String: Any] = ["status": MaintenanceStatus.completed.rawValue]
        if let cost = cost { updateData["cost"] = cost }
        if let notes = notes { updateData["notes"] = notes }
        
        let maintenance: Maintenance = try await apiClient.put("/maintenance/\(id)", body: updateData)
        
        await MainActor.run {
            if let index = self.maintenance.firstIndex(where: { $0.id == id }) {
                self.maintenance[index] = maintenance
            }
            self.updateMaintenanceCategories()
        }
    }
    
    // MARK: - Scheduling and Recommendations
    
    func generateMaintenanceSchedule(for vehicleId: String) async throws -> MaintenanceSchedule {
        let schedule: MaintenanceSchedule = try await apiClient.get("/maintenance/schedule/\(vehicleId)")
        return schedule
    }
    
    func getMaintenanceRecommendations(for vehicleId: String) async throws -> [MaintenanceRecommendation] {
        let recommendations: [MaintenanceRecommendation] = try await apiClient.get("/maintenance/recommendations/\(vehicleId)")
        return recommendations
    }
    
    // MARK: - Analytics and Statistics
    
    func getMaintenanceStats(vehicleId: String? = nil) async throws -> [String: Any] {
        let endpoint = vehicleId != nil ? "/maintenance/stats?vehicleId=\(vehicleId!)" : "/maintenance/stats"
        let stats: [String: Any] = try await apiClient.get(endpoint)
        return stats
    }
    
    func getTotalMaintenanceCost(for vehicleId: String? = nil) -> Double {
        let filteredMaintenance = vehicleId == nil ? maintenance : maintenance.filter { $0.vehicleId == vehicleId }
        return filteredMaintenance.compactMap { $0.cost }.reduce(0, +)
    }
    
    func getMaintenanceByType() -> [MaintenanceType: [Maintenance]] {
        return Dictionary(grouping: maintenance, by: { $0.type })
    }
    
    func getMaintenanceByStatus() -> [MaintenanceStatus: [Maintenance]] {
        return Dictionary(grouping: maintenance, by: { $0.status })
    }
    
    // MARK: - Business Logic
    
    private func updateMaintenanceCategories() {
        let now = Date()
        
        upcomingMaintenance = maintenance.filter { maintenance in
            maintenance.status == .upcoming && maintenance.date > now
        }.sorted { $0.date < $1.date }
        
        overdueMaintenance = maintenance.filter { maintenance in
            (maintenance.status == .due || maintenance.status == .overdue) || 
            (maintenance.status == .upcoming && maintenance.date <= now)
        }.sorted { $0.date < $1.date }
    }
    
    func checkMaintenanceDue(for vehicle: Vehicle) -> [MaintenanceRecommendation] {
        var recommendations: [MaintenanceRecommendation] = []
        
        // Oil change check
        let lastOilChange = maintenance
            .filter { $0.vehicleId == vehicle.id && $0.type == .oilChange && $0.status == .completed }
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
        
        // Tire rotation check
        let lastTireRotation = maintenance
            .filter { $0.vehicleId == vehicle.id && $0.type == .tireRotation && $0.status == .completed }
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
        
        // Brake service check
        let lastBrakeService = maintenance
            .filter { $0.vehicleId == vehicle.id && $0.type == .brakeService && $0.status == .completed }
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
        
        return recommendations
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func selectMaintenance(_ maintenance: Maintenance) {
        selectedMaintenance = maintenance
    }
    
    func clearSelection() {
        selectedMaintenance = nil
    }
    
    // MARK: - Search and Filter
    
    func searchMaintenance(query: String) -> [Maintenance] {
        guard !query.isEmpty else { return maintenance }
        
        return maintenance.filter { maintenance in
            maintenance.type.displayName.lowercased().contains(query.lowercased()) ||
            (maintenance.description?.lowercased().contains(query.lowercased()) ?? false) ||
            (maintenance.serviceProvider?.lowercased().contains(query.lowercased()) ?? false) ||
            maintenance.status.displayName.lowercased().contains(query.lowercased())
        }
    }
    
    func filterMaintenance(by type: MaintenanceType? = nil, status: MaintenanceStatus? = nil, vehicleId: String? = nil) -> [Maintenance] {
        var filtered = maintenance
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let vehicleId = vehicleId {
            filtered = filtered.filter { $0.vehicleId == vehicleId }
        }
        
        return filtered
    }
    
    func getMaintenanceHistory(for vehicleId: String) -> [Maintenance] {
        return maintenance
            .filter { $0.vehicleId == vehicleId && $0.status == .completed }
            .sorted { $0.date > $1.date }
    }
    
    func getNextMaintenance(for vehicleId: String) -> Maintenance? {
        return maintenance
            .filter { $0.vehicleId == vehicleId && ($0.status == .upcoming || $0.status == .due) }
            .min { $0.date < $1.date }
    }
} 
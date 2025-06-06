import Foundation
import Combine

class VehicleService: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var selectedVehicle: Vehicle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Methods
    
    func fetchVehicles() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let vehicles: [Vehicle] = try await apiClient.get("/vehicles")
            await MainActor.run {
                self.vehicles = vehicles
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchVehicle(id: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let vehicle: Vehicle = try await apiClient.get("/vehicles/\(id)")
            await MainActor.run {
                self.selectedVehicle = vehicle
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
    
    func createVehicle(
        make: String,
        model: String,
        year: Int,
        vin: String? = nil,
        licensePlate: String? = nil,
        mileage: Int,
        status: VehicleStatus = .active,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        notes: String? = nil
    ) async throws -> Vehicle {
        let vehicleData: [String: Any] = [
            "make": make,
            "model": model,
            "year": year,
            "vin": vin as Any,
            "licensePlate": licensePlate as Any,
            "mileage": mileage,
            "status": status.rawValue,
            "purchaseDate": purchaseDate?.iso8601String as Any,
            "purchasePrice": purchasePrice as Any,
            "notes": notes as Any
        ].compactMapValues { value in
            if case Optional<Any>.some(let unwrapped) = value {
                return unwrapped
            }
            return value is NSNull ? nil : value
        }
        
        let vehicle: Vehicle = try await apiClient.post("/vehicles", body: vehicleData)
        
        await MainActor.run {
            self.vehicles.append(vehicle)
        }
        
        return vehicle
    }
    
    func updateVehicle(
        id: String,
        make: String? = nil,
        model: String? = nil,
        year: Int? = nil,
        vin: String? = nil,
        licensePlate: String? = nil,
        mileage: Int? = nil,
        status: VehicleStatus? = nil,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        notes: String? = nil
    ) async throws -> Vehicle {
        var updateData: [String: Any] = [:]
        
        if let make = make { updateData["make"] = make }
        if let model = model { updateData["model"] = model }
        if let year = year { updateData["year"] = year }
        if let vin = vin { updateData["vin"] = vin }
        if let licensePlate = licensePlate { updateData["licensePlate"] = licensePlate }
        if let mileage = mileage { updateData["mileage"] = mileage }
        if let status = status { updateData["status"] = status.rawValue }
        if let purchaseDate = purchaseDate { updateData["purchaseDate"] = purchaseDate.iso8601String }
        if let purchasePrice = purchasePrice { updateData["purchasePrice"] = purchasePrice }
        if let notes = notes { updateData["notes"] = notes }
        
        let vehicle: Vehicle = try await apiClient.put("/vehicles/\(id)", body: updateData)
        
        await MainActor.run {
            if let index = self.vehicles.firstIndex(where: { $0.id == id }) {
                self.vehicles[index] = vehicle
            }
            if self.selectedVehicle?.id == id {
                self.selectedVehicle = vehicle
            }
        }
        
        return vehicle
    }
    
    func deleteVehicle(id: String) async throws {
        let _: [String: String] = try await apiClient.delete("/vehicles/\(id)")
        
        await MainActor.run {
            self.vehicles.removeAll { $0.id == id }
            if self.selectedVehicle?.id == id {
                self.selectedVehicle = nil
            }
        }
    }
    
    // MARK: - Image Upload
    
    func uploadVehicleImage(vehicleId: String, imageData: Data) async throws -> String {
        let response = try await apiClient.uploadImage(
            endpoint: "/vehicles/\(vehicleId)/image",
            imageData: imageData,
            filename: "vehicle_image.jpg"
        )
        
        guard let imageUrl = response["imageUrl"] as? String else {
            throw APIError.decodingError(NSError(domain: "ImageUploadError", code: 0, userInfo: nil))
        }
        
        return imageUrl
    }
    
    // MARK: - Statistics and Analysis
    
    func getVehicleStatistics(vehicleId: String) async throws -> [String: Any] {
        let stats: [String: Any] = try await apiClient.get("/vehicles/\(vehicleId)/stats")
        return stats
    }
    
    func getVehicleValue(vehicleId: String) async throws -> Double {
        let response: [String: Double] = try await apiClient.get("/vehicles/\(vehicleId)/value")
        return response["currentValue"] ?? 0.0
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func selectVehicle(_ vehicle: Vehicle) {
        selectedVehicle = vehicle
    }
    
    func clearSelection() {
        selectedVehicle = nil
    }
    
    // MARK: - Search and Filter
    
    func searchVehicles(query: String) -> [Vehicle] {
        guard !query.isEmpty else { return vehicles }
        
        return vehicles.filter { vehicle in
            vehicle.make.lowercased().contains(query.lowercased()) ||
            vehicle.model.lowercased().contains(query.lowercased()) ||
            "\(vehicle.year)".contains(query) ||
            (vehicle.licensePlate?.lowercased().contains(query.lowercased()) ?? false)
        }
    }
    
    func filterVehicles(by status: VehicleStatus) -> [Vehicle] {
        return vehicles.filter { $0.status == status }
    }
    
    func getActiveVehicles() -> [Vehicle] {
        return vehicles.filter { $0.status == .active }
    }
}

// MARK: - Date Extension for ISO8601
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 
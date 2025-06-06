import SwiftUI

struct VehicleListView: View {
    @StateObject private var vehicleService = VehicleService()
    @State private var searchText = ""
    @State private var selectedStatus: VehicleStatus? = nil
    @State private var showingAddVehicle = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search vehicles...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Filter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedStatus == nil
                            ) {
                                selectedStatus = nil
                            }
                            
                            ForEach(VehicleStatus.allCases, id: \.self) { status in
                                FilterButton(
                                    title: status.displayName,
                                    isSelected: selectedStatus == status
                                ) {
                                    selectedStatus = selectedStatus == status ? nil : status
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // Vehicles List
                if vehicleService.isLoading && vehicleService.vehicles.isEmpty {
                    Spacer()
                    ProgressView("Loading vehicles...")
                    Spacer()
                } else if filteredVehicles.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No vehicles found" : "No vehicles match your search")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Add your first vehicle to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Add Vehicle") {
                                showingAddVehicle = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredVehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                VehicleRowView(vehicle: vehicle)
                            }
                        }
                        .onDelete(perform: deleteVehicles)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await vehicleService.fetchVehicles()
                    }
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddVehicle = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                Task {
                    await vehicleService.fetchVehicles()
                }
            }
            .onChange(of: vehicleService.errorMessage) { error in
                if let error = error {
                    alertMessage = error
                    showingAlert = true
                    vehicleService.clearError()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredVehicles: [Vehicle] {
        var vehicles = vehicleService.vehicles
        
        // Apply status filter
        if let selectedStatus = selectedStatus {
            vehicles = vehicles.filter { $0.status == selectedStatus }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            vehicles = vehicleService.searchVehicles(query: searchText)
        }
        
        return vehicles
    }
    
    // MARK: - Methods
    
    private func deleteVehicles(offsets: IndexSet) {
        Task {
            for index in offsets {
                let vehicle = filteredVehicles[index]
                do {
                    try await vehicleService.deleteVehicle(id: vehicle.id)
                } catch {
                    alertMessage = "Failed to delete vehicle: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct VehicleRowView: View {
    let vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 16) {
            // Vehicle Image or Placeholder
            AsyncImage(url: URL(string: vehicle.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "car.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    )
            }
            .frame(width: 60, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                // Vehicle Name
                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.headline)
                    .lineLimit(1)
                
                // Details
                HStack {
                    if let licensePlate = vehicle.licensePlate {
                        Text(licensePlate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(vehicle.mileage.formatted()) mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Status Badge
                HStack {
                    StatusBadge(status: vehicle.status)
                    
                    Spacer()
                    
                    // Counts
                    if let count = vehicle._count {
                        HStack(spacing: 12) {
                            Label("\(count.expenses)", systemImage: "dollarsign.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Label("\(count.maintenance)", systemImage: "wrench.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: VehicleStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .clipShape(Capsule())
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Add Vehicle View

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vehicleService = VehicleService()
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var mileage = ""
    @State private var purchasePrice = ""
    @State private var purchaseDate = Date()
    @State private var notes = ""
    @State private var hasPurchaseDate = false
    @State private var hasPurchasePrice = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Make (e.g., Toyota)", text: $make)
                    TextField("Model (e.g., Camry)", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach(1990...Calendar.current.component(.year, from: Date()) + 1, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    
                    TextField("VIN (Optional)", text: $vin)
                    TextField("License Plate (Optional)", text: $licensePlate)
                    
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                }
                
                Section("Purchase Information") {
                    Toggle("Set Purchase Date", isOn: $hasPurchaseDate)
                    
                    if hasPurchaseDate {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    }
                    
                    Toggle("Set Purchase Price", isOn: $hasPurchasePrice)
                    
                    if hasPurchasePrice {
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!isFormValid || vehicleService.isLoading)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && !mileage.isEmpty && Int(mileage) != nil
    }
    
    // MARK: - Methods
    
    private func saveVehicle() {
        guard let mileageInt = Int(mileage) else { return }
        
        Task {
            do {
                let purchasePriceDouble = hasPurchasePrice ? Double(purchasePrice) : nil
                let purchaseDateValue = hasPurchaseDate ? purchaseDate : nil
                
                _ = try await vehicleService.createVehicle(
                    make: make,
                    model: model,
                    year: year,
                    vin: vin.isEmpty ? nil : vin,
                    licensePlate: licensePlate.isEmpty ? nil : licensePlate,
                    mileage: mileageInt,
                    purchaseDate: purchaseDateValue,
                    purchasePrice: purchasePriceDouble,
                    notes: notes.isEmpty ? nil : notes
                )
                
                dismiss()
            } catch {
                alertMessage = "Failed to save vehicle: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

#Preview {
    VehicleListView()
} 
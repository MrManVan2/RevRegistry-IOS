import SwiftUI

struct MaintenanceListView: View {
    @StateObject private var maintenanceService = MaintenanceService()
    @StateObject private var vehicleService = VehicleService()
    @State private var searchText = ""
    @State private var selectedStatus: MaintenanceStatus?
    @State private var selectedVehicle: Vehicle?
    @State private var showingAddMaintenance = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Filters
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search maintenance...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Vehicle Filter
                    if !vehicleService.vehicles.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterButton(
                                    title: "All Vehicles",
                                    isSelected: selectedVehicle == nil
                                ) {
                                    selectedVehicle = nil
                                }
                                
                                ForEach(vehicleService.vehicles) { vehicle in
                                    FilterButton(
                                        title: "\(vehicle.make) \(vehicle.model)",
                                        isSelected: selectedVehicle?.id == vehicle.id
                                    ) {
                                        selectedVehicle = selectedVehicle?.id == vehicle.id ? nil : vehicle
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Status Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All Status",
                                isSelected: selectedStatus == nil
                            ) {
                                selectedStatus = nil
                            }
                            
                            ForEach(MaintenanceStatus.allCases, id: \.self) { status in
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
                
                // Quick Actions Section
                if !maintenanceService.overdueMaintenance.isEmpty || !maintenanceService.upcomingMaintenance.isEmpty {
                    VStack(spacing: 12) {
                        if !maintenanceService.overdueMaintenance.isEmpty {
                            QuickActionCard(
                                title: "Overdue Maintenance",
                                subtitle: "\(maintenanceService.overdueMaintenance.count) items need attention",
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            ) {
                                selectedStatus = .overdue
                            }
                        }
                        
                        if !maintenanceService.upcomingMaintenance.isEmpty {
                            QuickActionCard(
                                title: "Upcoming Maintenance",
                                subtitle: "\(maintenanceService.upcomingMaintenance.count) items scheduled",
                                icon: "clock.fill",
                                color: .orange
                            ) {
                                selectedStatus = .upcoming
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Maintenance List
                if maintenanceService.isLoading && maintenanceService.maintenance.isEmpty {
                    Spacer()
                    ProgressView("Loading maintenance...")
                    Spacer()
                } else if filteredMaintenance.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No maintenance found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty && selectedStatus == nil && selectedVehicle == nil {
                            Text("Add your first maintenance record to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Add Maintenance") {
                                showingAddMaintenance = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredMaintenance) { maintenance in
                            MaintenanceRowView(maintenance: maintenance) {
                                if maintenance.status != .completed {
                                    Task {
                                        do {
                                            try await maintenanceService.completeMaintenance(id: maintenance.id)
                                        } catch {
                                            alertMessage = "Failed to complete maintenance: \(error.localizedDescription)"
                                            showingAlert = true
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteMaintenance)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await maintenanceService.fetchMaintenance()
                    }
                }
            }
            .navigationTitle("Maintenance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMaintenance = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMaintenance) {
                AddMaintenanceView(vehicles: vehicleService.vehicles)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadData()
            }
            .onChange(of: maintenanceService.errorMessage) { error in
                if let error = error {
                    alertMessage = error
                    showingAlert = true
                    maintenanceService.clearError()
                }
            }
            .onChange(of: selectedVehicle) { _ in
                Task {
                    await maintenanceService.fetchMaintenance(vehicleId: selectedVehicle?.id)
                }
            }
            .onChange(of: selectedStatus) { _ in
                Task {
                    await maintenanceService.fetchMaintenance(
                        vehicleId: selectedVehicle?.id,
                        status: selectedStatus
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredMaintenance: [Maintenance] {
        var maintenance = maintenanceService.maintenance
        
        // Apply search filter
        if !searchText.isEmpty {
            maintenance = maintenanceService.searchMaintenance(query: searchText)
        }
        
        // Filters are already applied by fetch calls
        
        return maintenance.sorted { $0.date > $1.date }
    }
    
    // MARK: - Methods
    
    private func loadData() {
        Task {
            async let maintenance: () = maintenanceService.fetchMaintenance()
            async let vehicles: () = vehicleService.fetchVehicles()
            
            await maintenance
            await vehicles
        }
    }
    
    private func deleteMaintenance(offsets: IndexSet) {
        Task {
            for index in offsets {
                let maintenance = filteredMaintenance[index]
                do {
                    try await maintenanceService.deleteMaintenance(id: maintenance.id)
                } catch {
                    alertMessage = "Failed to delete maintenance: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MaintenanceRowView: View {
    let maintenance: Maintenance
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: maintenance.type.icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // Type
                Text(maintenance.type.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                // Date and Mileage
                HStack {
                    Text(maintenance.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(maintenance.mileage.formatted()) mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Status and Priority
                HStack {
                    Text(maintenance.status.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(maintenance.status.color).opacity(0.2))
                        .foregroundColor(Color(maintenance.status.color))
                        .clipShape(Capsule())
                    
                    Text(maintenance.priority.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(maintenance.priority.color).opacity(0.2))
                        .foregroundColor(Color(maintenance.priority.color))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Cost
                if let cost = maintenance.cost {
                    Text("$\(cost.formatted(.number.precision(.fractionLength(2))))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                // Complete Button
                if maintenance.status != .completed {
                    Button("Complete") {
                        onComplete()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Maintenance View

struct AddMaintenanceView: View {
    let vehicles: [Vehicle]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var maintenanceService = MaintenanceService()
    
    @State private var selectedVehicle: Vehicle?
    @State private var type = MaintenanceType.oilChange
    @State private var status = MaintenanceStatus.upcoming
    @State private var date = Date()
    @State private var mileage = ""
    @State private var dueMileage = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var cost = ""
    @State private var priority = Priority.medium
    @State private var serviceProvider = ""
    @State private var hasCost = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Maintenance Details") {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .tag(vehicle as Vehicle?)
                        }
                    }
                    
                    Picker("Type", selection: $type) {
                        ForEach(MaintenanceType.allCases, id: \.self) { maintenanceType in
                            Label(maintenanceType.displayName, systemImage: maintenanceType.icon)
                                .tag(maintenanceType)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(MaintenanceStatus.allCases, id: \.self) { maintenanceStatus in
                            Text(maintenanceStatus.displayName).tag(maintenanceStatus)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                    
                    TextField("Due Mileage", text: $dueMileage)
                        .keyboardType(.numberPad)
                }
                
                Section("Additional Information") {
                    TextField("Description (Optional)", text: $description)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    
                    TextField("Service Provider (Optional)", text: $serviceProvider)
                    
                    Toggle("Add Cost", isOn: $hasCost)
                    
                    if hasCost {
                        TextField("Cost", text: $cost)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMaintenance()
                    }
                    .disabled(!isFormValid || maintenanceService.isLoading)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Pre-select first vehicle if available
                if selectedVehicle == nil && !vehicles.isEmpty {
                    selectedVehicle = vehicles.first
                }
                
                // Pre-fill mileage from selected vehicle
                if let vehicle = selectedVehicle {
                    mileage = String(vehicle.mileage)
                    dueMileage = String(vehicle.mileage + 5000) // Default to 5k miles ahead
                }
            }
            .onChange(of: selectedVehicle) { vehicle in
                if let vehicle = vehicle {
                    mileage = String(vehicle.mileage)
                    dueMileage = String(vehicle.mileage + 5000)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        selectedVehicle != nil && !mileage.isEmpty && Int(mileage) != nil && 
        !dueMileage.isEmpty && Int(dueMileage) != nil
    }
    
    // MARK: - Methods
    
    private func saveMaintenance() {
        guard let vehicle = selectedVehicle,
              let mileageInt = Int(mileage),
              let dueMileageInt = Int(dueMileage) else { return }
        
        Task {
            do {
                let costDouble = hasCost ? Double(cost) : nil
                
                _ = try await maintenanceService.createMaintenance(
                    vehicleId: vehicle.id,
                    type: type,
                    status: status,
                    date: date,
                    mileage: mileageInt,
                    dueMileage: dueMileageInt,
                    description: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes,
                    cost: costDouble,
                    priority: priority,
                    serviceProvider: serviceProvider.isEmpty ? nil : serviceProvider
                )
                
                dismiss()
            } catch {
                alertMessage = "Failed to save maintenance: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

#Preview {
    MaintenanceListView()
}
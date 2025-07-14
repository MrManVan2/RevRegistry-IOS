import SwiftUI

struct ExpenseListView: View {
    @StateObject private var expenseService = ExpenseService()
    @StateObject private var vehicleService = VehicleService()
    @State private var searchText = ""
    @State private var selectedType: ExpenseType?
    @State private var selectedVehicle: Vehicle?
    @State private var showingAddExpense = false
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
                        
                        TextField("Search expenses...", text: $searchText)
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
                    
                    // Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All Types",
                                isSelected: selectedType == nil
                            ) {
                                selectedType = nil
                            }
                            
                            ForEach(ExpenseType.allCases, id: \.self) { type in
                                FilterButton(
                                    title: type.displayName,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = selectedType == type ? nil : type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // Expenses List
                if expenseService.isLoading && expenseService.expenses.isEmpty {
                    Spacer()
                    ProgressView("Loading expenses...")
                    Spacer()
                } else if filteredExpenses.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No expenses found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty && selectedType == nil && selectedVehicle == nil {
                            Text("Add your first expense to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Add Expense") {
                                showingAddExpense = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await expenseService.fetchExpenses()
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(vehicles: vehicleService.vehicles)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadData()
            }
            .onChange(of: expenseService.errorMessage) { error in
                if let error = error {
                    alertMessage = error
                    showingAlert = true
                    expenseService.clearError()
                }
            }
            .onChange(of: selectedVehicle) { _ in
                Task {
                    await expenseService.fetchExpenses(vehicleId: selectedVehicle?.id)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredExpenses: [Expense] {
        var expenses = expenseService.expenses
        
        // Apply search filter
        if !searchText.isEmpty {
            expenses = expenseService.searchExpenses(query: searchText)
        }
        
        // Apply type filter
        if let selectedType = selectedType {
            expenses = expenses.filter { $0.type == selectedType }
        }
        
        // Apply vehicle filter (already handled by fetch)
        
        return expenses.sorted { $0.date > $1.date }
    }
    
    // MARK: - Methods
    
    private func loadData() {
        Task {
            async let expenses: () = expenseService.fetchExpenses()
            async let vehicles: () = vehicleService.fetchVehicles()
            
            await expenses
            await vehicles
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        Task {
            for index in offsets {
                let expense = filteredExpenses[index]
                do {
                    try await expenseService.deleteExpense(id: expense.id)
                } catch {
                    alertMessage = "Failed to delete expense: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: expense.type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // Description or Type
                Text(expense.description ?? expense.type.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                // Date and Mileage
                HStack {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(expense.mileage.formatted()) mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Category Badge
                Text(expense.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Amount
            Text("$\(expense.amount.formatted(.number.precision(.fractionLength(2))))")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Expense View

struct AddExpenseView: View {
    let vehicles: [Vehicle]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var expenseService = ExpenseService()
    
    @State private var selectedVehicle: Vehicle?
    @State private var date = Date()
    @State private var amount = ""
    @State private var description = ""
    @State private var type = ExpenseType.fuel
    @State private var category = ExpenseCategory.routine
    @State private var notes = ""
    @State private var mileage = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Camera-related state
    @StateObject private var cameraService = CameraService()
    @State private var showingReceiptOptions = false
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedReceiptImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .tag(vehicle as Vehicle?)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                }
                
                Section("Categorization") {
                    Picker("Type", selection: $type) {
                        ForEach(ExpenseType.allCases, id: \.self) { expenseType in
                            Label(expenseType.displayName, systemImage: expenseType.icon)
                                .tag(expenseType)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { expenseCategory in
                            Text(expenseCategory.displayName).tag(expenseCategory)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Receipt") {
                    Button(action: {
                        showingReceiptOptions = true
                    }) {
                        HStack {
                            Image(systemName: selectedReceiptImage != nil ? "photo.fill" : "camera.fill")
                                .foregroundColor(selectedReceiptImage != nil ? .green : .blue)
                            
                            Text(selectedReceiptImage != nil ? "Receipt Added" : "Add Receipt Photo")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedReceiptImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let receiptImage = selectedReceiptImage {
                        HStack {
                            Image(uiImage: receiptImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button("Remove") {
                                selectedReceiptImage = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                if !description.isEmpty && Double(amount) != nil {
                    Section("Smart Suggestions") {
                        let (suggestedType, suggestedCategory) = expenseService.suggestCategoryAndType(
                            for: description,
                            amount: Double(amount) ?? 0
                        )
                        
                        if suggestedType != type || suggestedCategory != category {
                            Button("Use suggested: \(suggestedType.displayName) - \(suggestedCategory.displayName)") {
                                type = suggestedType
                                category = suggestedCategory
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isFormValid || expenseService.isLoading)
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
                }
            }
            .onChange(of: selectedVehicle) { vehicle in
                if let vehicle = vehicle {
                    mileage = String(vehicle.mileage)
                }
            }
            .confirmationDialog("Add Receipt", isPresented: $showingReceiptOptions) {
                if CameraService.isCameraAvailable() {
                    Button("Take Photo") {
                        sourceType = .camera
                        showingImagePicker = true
                    }
                }
                
                if CameraService.isPhotoLibraryAvailable() {
                    Button("Choose from Library") {
                        sourceType = .photoLibrary
                        showingImagePicker = true
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedReceiptImage, isPresented: $showingImagePicker, sourceType: sourceType)
            }
            .onChange(of: cameraService.errorMessage) { error in
                if let error = error {
                    alertMessage = error
                    showingAlert = true
                    cameraService.clearError()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        selectedVehicle != nil && !amount.isEmpty && Double(amount) != nil && 
        !mileage.isEmpty && Int(mileage) != nil
    }
    
    // MARK: - Methods
    
    private func saveExpense() {
        guard let vehicle = selectedVehicle,
              let amountDouble = Double(amount),
              let mileageInt = Int(mileage) else { return }
        
        Task {
            do {
                let expense = try await expenseService.createExpense(
                    vehicleId: vehicle.id,
                    date: date,
                    amount: amountDouble,
                    description: description.isEmpty ? nil : description,
                    type: type,
                    category: category,
                    notes: notes.isEmpty ? nil : notes,
                    mileage: mileageInt
                )
                
                // Upload receipt if one was selected
                if let receiptImage = selectedReceiptImage {
                    await cameraService.uploadReceiptImage(receiptImage, expenseId: expense.id, expenseService: expenseService)
                }
                
                dismiss()
            } catch {
                alertMessage = "Failed to save expense: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

#Preview {
    ExpenseListView()
}
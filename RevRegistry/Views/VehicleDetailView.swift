import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @StateObject private var expenseService = ExpenseService()
    @StateObject private var maintenanceService = MaintenanceService()
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vehicle Header
                VehicleHeaderView(vehicle: vehicle)
                
                // Quick Stats
                QuickStatsView(
                    vehicle: vehicle,
                    totalExpenses: expenseService.getTotalExpenses(for: vehicle.id),
                    totalMaintenanceCost: maintenanceService.getTotalMaintenanceCost(for: vehicle.id)
                )
                
                // Tabbed Content
                VStack {
                    // Tab Picker
                    Picker("Content", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Expenses").tag(1)
                        Text("Maintenance").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        OverviewTabView(
                            vehicle: vehicle,
                            expenses: expenseService.expenses,
                            maintenance: maintenanceService.maintenance
                        )
                        .tag(0)
                        
                        ExpensesTabView(
                            vehicleId: vehicle.id,
                            expenses: expenseService.expenses
                        )
                        .tag(1)
                        
                        MaintenanceTabView(
                            vehicleId: vehicle.id,
                            maintenance: maintenanceService.maintenance
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                }
            }
            .padding()
        }
        .navigationTitle(vehicle.make + " " + vehicle.model)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            async let expenses: () = expenseService.fetchExpenses(vehicleId: vehicle.id)
            async let maintenance: () = maintenanceService.fetchMaintenance(vehicleId: vehicle.id)
            
            await expenses
            await maintenance
        }
    }
}

// MARK: - Supporting Views

struct VehicleHeaderView: View {
    let vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 16) {
            // Vehicle Image
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
                            .font(.largeTitle)
                    )
            }
            .frame(width: 120, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let licensePlate = vehicle.licensePlate {
                    Label(licensePlate, systemImage: "rectangle.and.text.magnifyingglass")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Label("\(vehicle.mileage.formatted()) miles", systemImage: "speedometer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                StatusBadge(status: vehicle.status)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickStatsView: View {
    let vehicle: Vehicle
    let totalExpenses: Double
    let totalMaintenanceCost: Double
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Expenses",
                value: "$\(totalExpenses.formatted(.number.precision(.fractionLength(0))))",
                icon: "dollarsign.circle.fill",
                color: .blue
            )
            
            StatCard(
                title: "Maintenance",
                value: "$\(totalMaintenanceCost.formatted(.number.precision(.fractionLength(0))))",
                icon: "wrench.fill",
                color: .orange
            )
            
            if let purchasePrice = vehicle.purchasePrice {
                StatCard(
                    title: "Purchase Price",
                    value: "$\(purchasePrice.formatted(.number.precision(.fractionLength(0))))",
                    icon: "purchased.circle.fill",
                    color: .green
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Tab Views

struct OverviewTabView: View {
    let vehicle: Vehicle
    let expenses: [Expense]
    let maintenance: [Maintenance]
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                
                if recentExpenses.isEmpty && recentMaintenance.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(recentExpenses.prefix(3)) { expense in
                        HStack {
                            Image(systemName: expense.type.icon)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(expense.description ?? expense.type.displayName)
                                    .font(.subheadline)
                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(expense.amount.formatted(.number.precision(.fractionLength(2))))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    ForEach(recentMaintenance.prefix(2)) { maintenance in
                        HStack {
                            Image(systemName: maintenance.type.icon)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text(maintenance.type.displayName)
                                    .font(.subheadline)
                                Text(maintenance.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(maintenance.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(maintenance.status.color).opacity(0.2))
                                .foregroundColor(Color(maintenance.status.color))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var recentExpenses: [Expense] {
        expenses.sorted { $0.date > $1.date }
    }
    
    private var recentMaintenance: [Maintenance] {
        maintenance.sorted { $0.date > $1.date }
    }
}

struct ExpensesTabView: View {
    let vehicleId: String
    let expenses: [Expense]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Expenses")
                .font(.headline)
            
            if expenses.isEmpty {
                Text("No expenses recorded")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(expenses.prefix(8)) { expense in
                    HStack {
                        Image(systemName: expense.type.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.description ?? expense.type.displayName)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(expense.amount.formatted(.number.precision(.fractionLength(2))))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MaintenanceTabView: View {
    let vehicleId: String
    let maintenance: [Maintenance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Maintenance History")
                .font(.headline)
            
            if maintenance.isEmpty {
                Text("No maintenance records")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(maintenance.prefix(8)) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.type.displayName)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(item.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(item.status.color).opacity(0.2))
                            .foregroundColor(Color(item.status.color))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        VehicleDetailView(vehicle: Vehicle(
            id: "1",
            userId: "user1",
            make: "Toyota",
            model: "Camry",
            year: 2020,
            vin: "1234567890",
            licensePlate: "ABC123",
            mileage: 50000,
            notes: nil,
            status: .active,
            imageUrl: nil,
            purchaseDate: Date(),
            purchasePrice: 25000,
            createdAt: Date(),
            updatedAt: Date(),
            expenses: nil,
            maintenance: nil,
            fuelEntries: nil,
            _count: Vehicle.Count(expenses: 15, maintenance: 8)
        ))
    }
} 
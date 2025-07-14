import Foundation
import Combine

class ExpenseService: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var selectedExpense: Expense?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Methods
    
    func fetchExpenses(vehicleId: String? = nil, startDate: Date? = nil, endDate: Date? = nil) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var queryParams: [String] = []
        if let vehicleId = vehicleId {
            queryParams.append("vehicleId=\(vehicleId)")
        }
        if let startDate = startDate {
            queryParams.append("startDate=\(startDate.iso8601String)")
        }
        if let endDate = endDate {
            queryParams.append("endDate=\(endDate.iso8601String)")
        }
        
        let queryString = queryParams.isEmpty ? "" : "?" + queryParams.joined(separator: "&")
        
        do {
            let expenses: [Expense] = try await apiClient.get("/expenses\(queryString)")
            await MainActor.run {
                self.expenses = expenses
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchExpense(id: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let expense: Expense = try await apiClient.get("/expenses/\(id)")
            await MainActor.run {
                self.selectedExpense = expense
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
    
    func createExpense(
        vehicleId: String,
        date: Date,
        amount: Double,
        description: String? = nil,
        type: ExpenseType,
        category: ExpenseCategory,
        notes: String? = nil,
        mileage: Int
    ) async throws -> Expense {
        let expenseData: [String: Any] = [
            "vehicleId": vehicleId,
            "date": date.iso8601String,
            "amount": amount,
            "description": description as Any,
            "type": type.rawValue,
            "category": category.rawValue,
            "notes": notes as Any,
            "mileage": mileage
        ].compactMapValues { value in
            if case Optional<Any>.some(let unwrapped) = value {
                return unwrapped
            }
            return value is NSNull ? nil : value
        }
        
        let expense: Expense = try await apiClient.post("/expenses", body: expenseData)
        
        await MainActor.run {
            // Insert expense in correct position to maintain sorted order (date descending)
            let insertIndex = self.expenses.firstIndex { $0.date <= expense.date } ?? self.expenses.count
            self.expenses.insert(expense, at: insertIndex)
        }
        
        return expense
    }
    
    func updateExpense(
        id: String,
        vehicleId: String? = nil,
        date: Date? = nil,
        amount: Double? = nil,
        description: String? = nil,
        type: ExpenseType? = nil,
        category: ExpenseCategory? = nil,
        notes: String? = nil,
        mileage: Int? = nil
    ) async throws -> Expense {
        var updateData: [String: Any] = [:]
        
        if let vehicleId = vehicleId { updateData["vehicleId"] = vehicleId }
        if let date = date { updateData["date"] = date.iso8601String }
        if let amount = amount { updateData["amount"] = amount }
        if let description = description { updateData["description"] = description }
        if let type = type { updateData["type"] = type.rawValue }
        if let category = category { updateData["category"] = category.rawValue }
        if let notes = notes { updateData["notes"] = notes }
        if let mileage = mileage { updateData["mileage"] = mileage }
        
        let expense: Expense = try await apiClient.put("/expenses/\(id)", body: updateData)
        
        await MainActor.run {
            if let index = self.expenses.firstIndex(where: { $0.id == id }) {
                self.expenses.remove(at: index)
                // Insert updated expense in correct position to maintain sorted order
                let insertIndex = self.expenses.firstIndex { $0.date <= expense.date } ?? self.expenses.count
                self.expenses.insert(expense, at: insertIndex)
            }
            if self.selectedExpense?.id == id {
                self.selectedExpense = expense
            }
        }
        
        return expense
    }
    
    func deleteExpense(id: String) async throws {
        let _: [String: String] = try await apiClient.delete("/expenses/\(id)")
        
        await MainActor.run {
            self.expenses.removeAll { $0.id == id }
            if self.selectedExpense?.id == id {
                self.selectedExpense = nil
            }
        }
    }
    
    // MARK: - Analytics and Statistics
    
    func getExpenseAnalysis(vehicleId: String? = nil, startDate: Date? = nil, endDate: Date? = nil) async throws -> ExpenseAnalysis {
        var queryParams: [String] = []
        if let vehicleId = vehicleId {
            queryParams.append("vehicleId=\(vehicleId)")
        }
        if let startDate = startDate {
            queryParams.append("startDate=\(startDate.iso8601String)")
        }
        if let endDate = endDate {
            queryParams.append("endDate=\(endDate.iso8601String)")
        }
        
        let queryString = queryParams.isEmpty ? "" : "?" + queryParams.joined(separator: "&")
        let analysis: ExpenseAnalysis = try await apiClient.get("/expenses/analysis\(queryString)")
        
        return analysis
    }
    
    func getTotalExpenses(for vehicleId: String? = nil) -> Double {
        let filteredExpenses = vehicleId == nil ? expenses : expenses.filter { $0.vehicleId == vehicleId }
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    func getExpensesByCategory() -> [ExpenseCategory: [Expense]] {
        return Dictionary(grouping: expenses, by: { $0.category })
    }
    
    func getExpensesByType() -> [ExpenseType: [Expense]] {
        return Dictionary(grouping: expenses, by: { $0.type })
    }
    
    func getMonthlyExpenses() -> [String: Double] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        let monthlyExpenses = Dictionary(grouping: expenses) { expense in
            formatter.string(from: expense.date)
        }
        
        return monthlyExpenses.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
    }
    
    // MARK: - Receipt Management
    
    func uploadReceipt(expenseId: String, imageData: Data) async throws -> String {
        let response = try await apiClient.uploadImage(
            endpoint: "/expenses/\(expenseId)/receipt",
            imageData: imageData,
            filename: "receipt.jpg"
        )
        
        guard let imageUrl = response["imageUrl"] as? String else {
            throw APIError.decodingError(NSError(domain: "ReceiptUploadError", code: 0, userInfo: nil))
        }
        
        return imageUrl
    }
    
    // MARK: - Export and Import
    
    func exportExpenses(format: String = "csv", vehicleId: String? = nil) async throws -> Data {
        var queryParams = ["format=\(format)"]
        if let vehicleId = vehicleId {
            queryParams.append("vehicleId=\(vehicleId)")
        }
        
        let queryString = "?" + queryParams.joined(separator: "&")
        let data: Data = try await apiClient.get("/expenses/export\(queryString)")
        
        return data
    }
    
    // MARK: - Smart Categorization
    
    func suggestCategoryAndType(for description: String, amount: Double) -> (ExpenseType, ExpenseCategory) {
        let lowercased = description.lowercased()
        
        // Fuel detection
        if lowercased.contains("gas") || lowercased.contains("fuel") || lowercased.contains("shell") || 
           lowercased.contains("exxon") || lowercased.contains("bp") || lowercased.contains("chevron") {
            return (.fuel, .routine)
        }
        
        // Maintenance detection
        if lowercased.contains("oil") || lowercased.contains("tire") || lowercased.contains("brake") ||
           lowercased.contains("filter") || lowercased.contains("tune") {
            return (.maintenance, amount > 500 ? .emergency : .routine)
        }
        
        // Insurance detection
        if lowercased.contains("insurance") || lowercased.contains("policy") || lowercased.contains("premium") {
            return (.insurance, .legal)
        }
        
        // Registration detection
        if lowercased.contains("registration") || lowercased.contains("dmv") || lowercased.contains("license") {
            return (.registration, .legal)
        }
        
        // Repair detection
        if lowercased.contains("repair") || lowercased.contains("fix") || lowercased.contains("replace") {
            return (.repair, amount > 1000 ? .emergency : .routine)
        }
        
        return (.other, .other)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func selectExpense(_ expense: Expense) {
        selectedExpense = expense
    }
    
    func clearSelection() {
        selectedExpense = nil
    }
    
    // MARK: - Search and Filter
    
    func searchExpenses(query: String) -> [Expense] {
        guard !query.isEmpty else { return expenses }
        
        return expenses.filter { expense in
            (expense.description?.lowercased().contains(query.lowercased()) ?? false) ||
            expense.type.displayName.lowercased().contains(query.lowercased()) ||
            expense.category.displayName.lowercased().contains(query.lowercased()) ||
            "\(expense.amount)".contains(query)
        }
    }
    
    func filterExpenses(by type: ExpenseType? = nil, category: ExpenseCategory? = nil, vehicleId: String? = nil) -> [Expense] {
        var filtered = expenses
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let vehicleId = vehicleId {
            filtered = filtered.filter { $0.vehicleId == vehicleId }
        }
        
        return filtered
    }
    
    func getRecentExpenses(limit: Int = 10) -> [Expense] {
        return Array(expenses.sorted { $0.date > $1.date }.prefix(limit))
    }
} 
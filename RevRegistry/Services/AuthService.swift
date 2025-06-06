import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let response: LoginResponse = try await apiClient.post("/auth/signin", body: loginRequest)
            
            // Save auth data
            KeychainHelper.saveToken(response.token)
            KeychainHelper.saveUserId(response.user.id)
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let registerRequest = RegisterRequest(email: email, password: password, name: name)
            let response: LoginResponse = try await apiClient.post("/auth/register", body: registerRequest)
            
            // Save auth data
            KeychainHelper.saveToken(response.token)
            KeychainHelper.saveUserId(response.user.id)
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        KeychainHelper.clearToken()
        KeychainHelper.clearUserId()
        
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    func checkAuthStatus() {
        guard let token = KeychainHelper.getToken(),
              let userId = KeychainHelper.getUserId() else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        // Validate token with server
        Task {
            do {
                let user: User = try await apiClient.get("/auth/session")
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    self.signOut()
                }
            }
        }
    }
    
    // MARK: - Profile Methods
    
    func updateProfile(name: String?, email: String?) async throws {
        guard let userId = currentUser?.id else {
            throw APIError.unauthorized
        }
        
        let updateData = ["name": name, "email": email].compactMapValues { $0 }
        let updatedUser: User = try await apiClient.put("/auth/profile", body: updateData)
        
        await MainActor.run {
            self.currentUser = updatedUser
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        let passwordData = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        
        let _: [String: String] = try await apiClient.put("/auth/password", body: passwordData)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
} 
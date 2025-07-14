import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var registrationEmail: String?
    @Published var isAwaitingVerification = false
    
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
            // Handle email not verified error specially
            if let apiError = error as? APIError,
               case .serverError(let statusCode, let data) = apiError,
               statusCode == 401,
               let errorData = data,
               let errorString = String(data: errorData, encoding: .utf8),
               errorString.contains("EMAIL_NOT_VERIFIED") {
                
                await MainActor.run {
                    self.registrationEmail = email
                    self.isAwaitingVerification = true
                    self.errorMessage = "Please verify your email address to continue"
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
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
            let response: RegisterResponse = try await apiClient.post("/auth/register", body: registerRequest)
            
            await MainActor.run {
                self.registrationEmail = email
                self.isAwaitingVerification = true
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func verifyEmail(email: String, verificationCode: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let verifyRequest = VerifyEmailRequest(email: email, verificationCode: verificationCode)
            let response: VerifyEmailResponse = try await apiClient.post("/auth/verify-email", body: verifyRequest)
            
            // Save auth data
            KeychainHelper.saveToken(response.token)
            KeychainHelper.saveUserId(response.user.id)
            
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.isAwaitingVerification = false
                self.registrationEmail = nil
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func resendVerificationCode(email: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let resendRequest = ResendVerificationRequest(email: email)
            let response: ResendVerificationResponse = try await apiClient.post("/auth/resend-verification", body: resendRequest)
            
            await MainActor.run {
                self.isLoading = false
                // Show success message or handle response
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
    
    func clearVerificationState() {
        isAwaitingVerification = false
        registrationEmail = nil
    }
} 
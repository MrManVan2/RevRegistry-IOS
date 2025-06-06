import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Rev Registry")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your vehicle expenses and maintenance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 20) {
                    if isSignUp {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Action Button
                Button(action: {
                    if isSignUp {
                        signUp()
                    } else {
                        signIn()
                    }
                }) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .disabled(authService.isLoading || !isFormValid)
                .opacity(authService.isLoading || !isFormValid ? 0.6 : 1.0)
                
                // Toggle Sign In/Sign Up
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                        clearForm()
                    }
                }) {
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Additional Options
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Text("or")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    // Google Sign In Button (placeholder)
                    Button(action: {
                        // TODO: Implement Google Sign In
                        showingAlert = true
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    // Demo Account Button
                    Button(action: {
                        fillDemoCredentials()
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("Use Demo Account")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("Feature Coming Soon", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text("Google Sign In will be available in a future update.")
        }
        .onAppear {
            authService.clearError()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && 
                   password.count >= 6 && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        }
    }
    
    // MARK: - Methods
    
    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
    
    private func signUp() {
        Task {
            await authService.signUp(email: email, password: password, name: name)
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        name = ""
        authService.clearError()
    }
    
    private func fillDemoCredentials() {
        email = "demo@revregistry.com"
        password = "demo123"
        if isSignUp {
            name = "Demo User"
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
} 
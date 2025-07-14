import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var verificationCode = ""
    @State private var canResend = true
    @State private var resendTimer = 60
    @State private var showingSuccessMessage = false
    
    let email: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We've sent a verification code to:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please enter the 6-digit code below")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("Verification Code", text: $verificationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .disabled(authService.isLoading)
                
                Button(action: verifyEmail) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Verify Email")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(verificationCode.count == 6 && !authService.isLoading ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(verificationCode.count != 6 || authService.isLoading)
                
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Text("Didn't receive the code?")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if canResend {
                    Button("Resend Code") {
                        resendVerificationCode()
                    }
                    .disabled(authService.isLoading)
                } else {
                    Text("Resend in \(resendTimer)s")
                        .foregroundColor(.secondary)
                        .onAppear {
                            startResendTimer()
                        }
                }
                
                Button("Use Different Email") {
                    authService.clearVerificationState()
                }
                .foregroundColor(.blue)
                .disabled(authService.isLoading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 40)
        .navigationBarBackButtonHidden(true)
    }
    
    private func verifyEmail() {
        Task {
            await authService.verifyEmail(email: email, verificationCode: verificationCode)
        }
    }
    
    private func resendVerificationCode() {
        Task {
            await authService.resendVerificationCode(email: email)
            canResend = false
            resendTimer = 60
            startResendTimer()
        }
    }
    
    private func startResendTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendTimer > 0 {
                resendTimer -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

#Preview {
    EmailVerificationView(email: "user@example.com")
        .environmentObject(AuthService())
}
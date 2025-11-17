//
//  DebugAuthView.swift
//  wealthiq
//
//  Created on 11/17/25.
//
//  Debug authentication view for local development
//  This bypasses Sign in with Apple and uses email/password auth
//

import SwiftUI

struct DebugAuthView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isAuthenticated: Bool = false
    
    // Pre-filled test emails for convenience
    private let testEmails = [
        "test@example.com",
        "user1@test.com",
        "user2@test.com",
        "demo@wealthiq.com"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Debug Authentication")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Local Development Mode")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                #if DEBUG
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("DEBUG BUILD ONLY")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                #endif
            }
            .padding(.top, 40)
            
            // Main content
            VStack(spacing: 20) {
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter email or select below", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Quick select test emails
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Select")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(testEmails, id: \.self) { testEmail in
                                Button {
                                    email = testEmail
                                } label: {
                                    Text(testEmail)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(email == testEmail ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundStyle(email == testEmail ? .white : .primary)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                
                // Sign In / Sign Up Button
                Button {
                    Task {
                        await authenticate()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In / Sign Up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(email.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(email.isEmpty || isLoading)
                
                // Anonymous sign in option
                Button {
                    Task {
                        await authenticateAnonymously()
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                        Text("Continue Anonymously")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                // Messages
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let success = successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer info
            VStack(spacing: 4) {
                Text("Debug Mode Info")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("• Uses password: 'test123456'")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("• Creates user if doesn't exist")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("• Bypasses email verification")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Authentication Methods
    
    private func authenticate() async {
        guard !email.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Try to sign in first
            let debugPassword = "test123456" // Fixed password for debug mode
            
            do {
                try await supabaseManager.signIn(email: email, password: debugPassword)
                successMessage = "Signed in successfully as \(email)"
                isAuthenticated = true
            } catch {
                // If sign in fails, try to sign up
                print("Sign in failed, attempting sign up: \(error.localizedDescription)")
                
                do {
                    try await supabaseManager.signUp(email: email, password: debugPassword)
                    // After sign up, sign in automatically
                    try await supabaseManager.signIn(email: email, password: debugPassword)
                    successMessage = "Created account and signed in as \(email)"
                    isAuthenticated = true
                } catch {
                    throw error
                }
            }
            
            // Check authentication status
            if await supabaseManager.isAuthenticated() {
                print("✅ User authenticated successfully")
                // Dismiss this view or navigate to onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // You can add navigation logic here
                    NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
                }
            }
            
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            print("❌ Authentication error: \(error)")
        }
        
        isLoading = false
    }
    
    private func authenticateAnonymously() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Generate a random email for anonymous user
            let randomId = UUID().uuidString.prefix(8)
            let anonymousEmail = "anon-\(randomId)@wealthiq.local"
            
            // Create anonymous user with generated email
            try await supabaseManager.signUp(email: anonymousEmail, password: "anonymous-\(randomId)")
            try await supabaseManager.signIn(email: anonymousEmail, password: "anonymous-\(randomId)")
            
            successMessage = "Signed in anonymously"
            isAuthenticated = true
            
            // Navigate after successful auth
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
            }
            
        } catch {
            errorMessage = "Anonymous sign in failed: \(error.localizedDescription)"
            print("❌ Anonymous auth error: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let debugAuthCompleted = Notification.Name("debugAuthCompleted")
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - Preview
struct DebugAuthView_Previews: PreviewProvider {
    static var previews: some View {
        DebugAuthView()
    }
}

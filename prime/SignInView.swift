//
//  SignInView.swift
//  prime
//
//  Created on 11/19/25.
//

import AuthenticationServices
import CryptoKit
import SwiftUI

struct SignInView: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var currentNonce: String?
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      // Logo or App Name
      VStack(spacing: 16) {
        Image(systemName: "sparkles")
          .font(.system(size: 80))
          .foregroundStyle(.blue)
          .symbolEffect(.bounce, value: isLoading)

        Text("Welcome to Prime")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Your personal growth companion")
          .font(.body)
          .foregroundStyle(.secondary)
      }

      Spacer()

      if isLoading {
        ProgressView()
          .scaleEffect(1.5)
          .padding()
      } else {
        // Sign in with Apple Button
        SignInWithAppleButton(
          onRequest: { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
          },
          onCompletion: { result in
            switch result {
            case .success(let authResults):
              switch authResults.credential {
              case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let nonce = currentNonce else {
                  fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                  print("Unable to fetch identity token")
                  return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                  print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                  return
                }

                Task {
                  await handleSignIn(idToken: idTokenString, nonce: nonce)
                }

              default:
                break
              }
            case .failure(let error):
              print("Sign in with Apple failed: \(error.localizedDescription)")
              errorMessage = "Sign in failed. Please try again."
            }
          }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(12)
        .padding(.horizontal, 40)
      }

      if let error = errorMessage {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .padding()
      }

      Spacer()
        .frame(height: 40)
    }
    .padding()
  }

  private func handleSignIn(idToken: String, nonce: String) async {
    isLoading = true
    errorMessage = nil

    do {
      // Try with HASHED nonce first as that seems to be what Supabase expects with this configuration
      let hashedNonce = sha256(nonce)
      print("⏳ [SignInView] Attempting sign in with HASHED nonce...")
      try await supabaseManager.signInWithApple(idToken: idToken, nonce: hashedNonce)
      print("✅ [SignInView] Successfully signed in with Apple (using hashed nonce)")
      
      // Notify that auth is complete so ContentView can refresh
      NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
    } catch {
      print("❌ [SignInView] Sign in error with HASHED nonce: \(error)")
      
      // Retry with RAW nonce
      print("🔄 [SignInView] Retrying with RAW nonce...")
      do {
        try await supabaseManager.signInWithApple(idToken: idToken, nonce: nonce)
        print("✅ [SignInView] Successfully signed in with Apple (using raw nonce)")
        NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
      } catch {
        print("❌ [SignInView] Sign in error with RAW nonce: \(error)")
        errorMessage = "Authentication failed. Please try again."
      }
    }

    isLoading = false
  }

  // MARK: - Crypto Helpers

  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
      fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }

    let charset: [Character] =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    let nonce = randomBytes.map { byte in
      // Pick a random character from the set, wrapping around if needed.
      charset[Int(byte) % charset.count]
    }

    return String(nonce)
  }

  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()

    return hashString
  }
}

#Preview {
  SignInView()
}


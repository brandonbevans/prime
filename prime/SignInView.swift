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
  @State private var showDebugAuth = false

  var body: some View {
    ZStack {
      // Background
      OnboardingBackground()

      VStack(spacing: 0) {
        #if DEBUG
        HStack {
          Spacer()
          Button(action: {
            showDebugAuth = true
          }) {
            Image(systemName: "ladybug.fill")
              .font(.system(size: 24))
              .foregroundStyle(.gray.opacity(0.5))
              .padding()
          }
        }
        #endif

        Spacer()

        // Logo
        Image("regularlogo")
          .resizable()
          .scaledToFit()
          .frame(width: 280, height: 280)
          .opacity(0.7)
          .frame(maxWidth: .infinity) // Ensure centering horizontally

        // Tagline
        Text("Are you prime?")
          .font(.system(size: 32, weight: .semibold))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6)) // Light grey text
          .padding(.horizontal, 20)
          .padding(.top, -20) // Negative padding to pull it closer if needed, or just rely on spacing
          .frame(maxWidth: .infinity) // Ensure centering horizontally

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
          .cornerRadius(25) // Pill shape
          .padding(.horizontal, 40)
        }

        if let error = errorMessage {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
            .padding()
        }
        
        Spacer()
          .frame(height: 20)
      }
      .padding()
    }
    .sheet(isPresented: $showDebugAuth) {
      DebugAuthView()
    }
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

// MARK: - Background

private struct OnboardingBackground: View {
  var body: some View {
    Color.white
      .ignoresSafeArea()
      .overlay(
        AccentBlob(
          palette: .top,
          stretch: CGSize(width: 1.45, height: 1.05),
          rotation: .degrees(-18)
        )
        .frame(width: 280, height: 260)
        .offset(x: 270, y: -42),
        alignment: .topLeading
      )
      .overlay(
        AccentBlob(
          palette: .bottom,
          stretch: CGSize(width: 1.3, height: 1.15),
          rotation: .degrees(16)
        )
        .frame(width: 340, height: 330)
        .offset(x: -210, y: 400),
        alignment: .topLeading
      )
      .overlay(
        RadialGradient(
          gradient: Gradient(colors: [
            Color(red: 0.37, green: 0.29, blue: 0.58).opacity(0.12),
            Color.white.opacity(0),
          ]),
          center: .center,
          startRadius: 40,
          endRadius: 520
        )
      )
      .ignoresSafeArea()
  }

  private struct AccentBlob: View {
    struct Palette {
      let core: Color
      let highlight: Color
      let glow: Color

      static let top = Palette(
        core: Color(red: 0.62, green: 0.83, blue: 1.0),
        highlight: Color(red: 0.72, green: 0.88, blue: 1.0),
        glow: Color(red: 0.64, green: 0.86, blue: 0.99)
      )

      static let bottom = Palette(
        core: Color(red: 0.62, green: 0.83, blue: 1.0),
        highlight: Color(red: 0.72, green: 0.88, blue: 1.0),
        glow: Color(red: 0.64, green: 0.86, blue: 0.99)
      )
    }

    let palette: Palette
    let stretch: CGSize
    let rotation: Angle

    init(
      palette: Palette,
      stretch: CGSize = CGSize(width: 1, height: 1),
      rotation: Angle = .zero
    ) {
      self.palette = palette
      self.stretch = stretch
      self.rotation = rotation
    }

    var body: some View {
      GeometryReader { proxy in
        let maxDimension = max(proxy.size.width, proxy.size.height)
        let haloSize = maxDimension * 1.45
        let coreSize = maxDimension * 1.05
        let highlightSize = maxDimension * 0.92
        let haloBlur = haloSize * 0.35
        let coreBlur = coreSize * 0.28
        let highlightBlur = highlightSize * 0.32

        ZStack {
          haloLayer(size: haloSize, blur: haloBlur)
          coreLayer(size: coreSize, blur: coreBlur)
          highlightLayer(size: highlightSize, blur: highlightBlur)
        }
        .scaleEffect(x: stretch.width, y: stretch.height, anchor: .center)
        .rotationEffect(rotation)
        .frame(width: proxy.size.width, height: proxy.size.height)
        .compositingGroup()
        .allowsHitTesting(false)
      }
    }

    @ViewBuilder
    private func haloLayer(size: CGFloat, blur: CGFloat) -> some View {
      Ellipse()
        .fill(
          RadialGradient(
            gradient: Gradient(stops: [
              .init(color: palette.glow.opacity(0.26), location: 0),
              .init(color: palette.glow.opacity(0.12), location: 0.35),
              .init(color: palette.glow.opacity(0.0), location: 1),
            ]),
            center: .center,
            startRadius: 0,
            endRadius: size
          )
        )
        .frame(width: size, height: size)
        .blur(radius: blur)
        .blendMode(.plusLighter)
    }

    @ViewBuilder
    private func coreLayer(size: CGFloat, blur: CGFloat) -> some View {
      Ellipse()
        .fill(
          RadialGradient(
            gradient: Gradient(stops: [
              .init(color: palette.core.opacity(0.55), location: 0),
              .init(color: palette.core.opacity(0.18), location: 0.4),
              .init(color: palette.core.opacity(0.0), location: 1),
            ]),
            center: .center,
            startRadius: 0,
            endRadius: size
          )
        )
        .frame(width: size, height: size * 0.92)
        .blur(radius: blur)
        .blendMode(.plusLighter)
    }

    @ViewBuilder
    private func highlightLayer(size: CGFloat, blur: CGFloat) -> some View {
      Ellipse()
        .fill(
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: palette.highlight.opacity(0.48), location: 0),
              .init(color: palette.highlight.opacity(0.0), location: 1),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: size, height: size * 0.78)
        .blur(radius: blur)
        .blendMode(.plusLighter)
    }
  }
}

#Preview {
  SignInView()
}


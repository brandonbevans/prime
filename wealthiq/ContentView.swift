//
//  ContentView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SuperwallKit
import SwiftUI

struct ContentView: View {
  @State private var isAuthenticated = false
  @State private var isCheckingAuth = true
  @State private var hasCompletedOnboarding = false
  @StateObject private var supabaseManager = SupabaseManager.shared

  var body: some View {
    Group {
      if isCheckingAuth {
        // Loading state while checking authentication
        VStack {
          ProgressView()
          Text("Loading...")
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
      } else if isAuthenticated {
        // User is authenticated, check if onboarding is complete
        if hasCompletedOnboarding {
          HomeScreen()
        } else {
          OnboardingView()
            .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
              hasCompletedOnboarding = true
            }
        }
      } else {
        // User needs to authenticate
        #if DEBUG
          // In debug mode, show the debug auth view
          DebugAuthView()
            .onReceive(NotificationCenter.default.publisher(for: .debugAuthCompleted)) { _ in
              // Re-check authentication after debug auth completes
              Task {
                await checkAuthentication()
              }
            }
        #else
          // In production, you would show your normal auth flow
          // For now, just show onboarding
          OnboardingView()
        #endif
      }
    }
    .task {
      await checkAuthentication()
    }
  }

  private func checkAuthentication() async {
    isCheckingAuth = true

    // Check if user is already authenticated
    isAuthenticated = await supabaseManager.isAuthenticated()

    if isAuthenticated {
      print("✅ User is already authenticated")
      // Check if we can get the user ID and onboarding status
      do {
        let userId = try await supabaseManager.getCurrentUserId()
        print("  - User ID: \(userId)")

        // Check if user has completed onboarding
        if let profile = try await supabaseManager.fetchUserProfile() {
          hasCompletedOnboarding = profile.onboardingCompleted
          print("  - Onboarding completed: \(hasCompletedOnboarding)")
        } else {
          // No profile yet, needs onboarding
          hasCompletedOnboarding = false
          print("  - No profile found, needs onboarding")
        }
      } catch {
        print("⚠️ Could not get user ID: \(error)")
        // Session might be invalid, sign out
        try? await supabaseManager.signOut()
        isAuthenticated = false
        hasCompletedOnboarding = false
      }
    } else {
      print("❌ User is not authenticated")
      hasCompletedOnboarding = false
    }

    isCheckingAuth = false
  }

  // Public method to get current user ID (for debugging)
  func getCurrentUserId() async throws -> UUID {
    return try await supabaseManager.getCurrentUserId()
  }
}

#Preview {
  ContentView()
}

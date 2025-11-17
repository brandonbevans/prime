//
//  HomeScreen.swift
//  wealthiq
//
//  Created on 11/17/25.
//

import SwiftUI

struct HomeScreen: View {
  @StateObject private var supabaseManager = SupabaseManager.shared
  @State private var userName: String = "there"
  @State private var showingDebugMenu = false
  
  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [
          Color(red: 0.95, green: 0.92, blue: 1.0),
          Color(red: 0.85, green: 0.95, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      
      VStack(spacing: 30) {
        // Debug button (top right)
        #if DEBUG
        HStack {
          Spacer()
          Button(action: {
            showingDebugMenu = true
          }) {
            Image(systemName: "gearshape.fill")
              .font(.system(size: 20))
              .foregroundColor(.gray)
              .padding(8)
              .background(Color.white.opacity(0.9))
              .clipShape(Circle())
              .shadow(radius: 2)
          }
          .padding(.trailing, 16)
          .padding(.top, 8)
        }
        #endif
        
        Spacer()
        
        // Welcome message
        VStack(spacing: 20) {
          Text("Hello!")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
          
          Text("Welcome to Prime!")
            .font(.system(size: 32, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 0.39, green: 0.27, blue: 0.92))
            .multilineTextAlignment(.center)
          
          if !userName.isEmpty && userName != "there" && userName != "User" {
            Text("Great to see you, \(userName)!")
              .font(.system(size: 20, weight: .medium, design: .rounded))
              .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
              .padding(.top, 10)
          }
        }
        .padding(.horizontal, 30)
        
        Spacer()
        
        // Placeholder for future content
        VStack(spacing: 16) {
          Image(systemName: "sparkles")
            .font(.system(size: 40))
            .foregroundColor(Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.6))
          
          Text("Your journey begins here")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(red: 0.36, green: 0.33, blue: 0.46))
            .italic()
        }
        .padding(.bottom, 60)
      }
    }
    .task {
      await loadUserName()
    }
    #if DEBUG
    .actionSheet(isPresented: $showingDebugMenu) {
      ActionSheet(
        title: Text("Debug Menu"),
        message: Text("Developer options"),
        buttons: [
          .destructive(Text("Sign Out")) {
            Task {
              do {
                try await supabaseManager.signOut()
                print("✅ Signed out successfully")
                // Post notification to refresh auth state
                NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
              } catch {
                print("❌ Sign out failed: \(error)")
              }
            }
          },
          .default(Text("Reset Onboarding")) {
            Task {
              do {
                // Clear onboarding completed flag
                if let userId = try? await supabaseManager.getCurrentUserId() {
                  // You could add a method to reset onboarding_completed to false
                  print("🔄 Reset onboarding for user: \(userId)")
                }
                // Sign out to restart flow
                try await supabaseManager.signOut()
                NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
              } catch {
                print("❌ Reset failed: \(error)")
              }
            }
          },
          .cancel()
        ]
      )
    }
    #endif
  }
  
  private func loadUserName() async {
    do {
      if let profile = try await supabaseManager.fetchUserProfile() {
        await MainActor.run {
          userName = profile.firstName
        }
      }
    } catch {
      print("Could not load user name: \(error)")
    }
  }
}

#Preview {
  HomeScreen()
}

//
//  ProfileView.swift
//  prime
//
//  Created on 11/24/25.
//

import SwiftUI

struct ProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var userProfile: SupabaseManager.UserProfile?
  @State private var firstName: String?
  @State private var selectedCoachingStyle: CoachingStyle?
  @State private var isLoading = true
  @State private var isSaving = false
  @State private var activeAlert: ActiveAlert?
  @State private var isDeleting = false
  @State private var errorMessage: String?
  
  enum ActiveAlert: Identifiable {
    case signOut
    case deleteAccount
    
    var id: Self { self }
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        Color(red: 0.97, green: 0.97, blue: 0.98)
          .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: 24) {
            // Profile Header
            profileHeader
              .padding(.top, 16)
            
            // Coaching Style Section
            coachingStyleSection
            
            Spacer(minLength: 40)
            
            // Sign Out Button
            signOutButton
            
            // Delete Account Button
            deleteAccountButton
              .padding(.top, 12)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 40)
        }
        
        if isLoading {
          ProgressView()
            .scaleEffect(1.2)
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
        }
      }
      .alert(item: $activeAlert) { alert in
        switch alert {
        case .signOut:
          Alert(
            title: Text("Sign Out"),
            message: Text("Are you sure you want to sign out?"),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Sign Out")) {
              signOut()
            }
          )
        case .deleteAccount:
          Alert(
            title: Text("Delete Account"),
            message: Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed."),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Delete Account")) {
              deleteAccount()
            }
          )
        }
      }
      .task {
        await loadProfile()
      }
    }
  }
  
  // MARK: - Profile Header
  
  private var profileHeader: some View {
    VStack(spacing: 16) {
      // Avatar
      Circle()
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.3, green: 0.3, blue: 0.35),
              Color(red: 0.2, green: 0.2, blue: 0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 80, height: 80)
        .overlay(
          Group {
            if let name = firstName, !name.isEmpty {
              Text(name.prefix(1).uppercased())
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
            } else {
              Image(systemName: "person.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
            }
          }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
      
      // Name
      Text(firstName ?? "Your Profile")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(Color.white)
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
  }
  
  // MARK: - Coaching Style Section
  
  private var coachingStyleSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Coaching Style")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
        .textCase(.uppercase)
        .tracking(0.5)
      
      VStack(spacing: 10) {
        ForEach(CoachingStyle.allCases, id: \.rawValue) { style in
          CoachingStyleOption(
            style: style,
            isSelected: selectedCoachingStyle == style,
            isSaving: isSaving && selectedCoachingStyle == style
          ) {
            selectCoachingStyle(style)
          }
        }
      }
      
      if let errorMessage {
        Text(errorMessage)
          .font(.system(size: 13))
          .foregroundColor(.red)
          .padding(.top, 4)
      }
    }
    .padding(20)
    .background(Color.white)
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
  }
  
  // MARK: - Sign Out Button
  
  private var signOutButton: some View {
    Button(action: {
      activeAlert = .signOut
    }) {
      HStack {
        Image(systemName: "rectangle.portrait.and.arrow.right")
          .font(.system(size: 18))
        Text("Sign Out")
          .font(.system(size: 16, weight: .medium))
      }
      .foregroundColor(.red)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(Color.white)
      .cornerRadius(14)
      .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
  }
  
  // MARK: - Delete Account Button
  
  private var deleteAccountButton: some View {
    Button(action: {
      activeAlert = .deleteAccount
    }) {
      HStack {
        if isDeleting {
          ProgressView()
            .scaleEffect(0.8)
            .tint(Color(red: 0.6, green: 0.2, blue: 0.2))
        } else {
          Image(systemName: "trash")
            .font(.system(size: 18))
        }
        Text(isDeleting ? "Deleting..." : "Delete Account")
          .font(.system(size: 16, weight: .medium))
      }
      .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.2))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(Color(red: 1.0, green: 0.95, blue: 0.95))
      .cornerRadius(14)
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(Color(red: 0.6, green: 0.2, blue: 0.2).opacity(0.3), lineWidth: 1)
      )
    }
    .disabled(isDeleting)
  }
  
  // MARK: - Actions
  
  private func loadProfile() async {
    isLoading = true
    defer { isLoading = false }
    
    // Get first name from auth metadata (Sign In with Apple)
    firstName = await SupabaseManager.shared.getCurrentUserFirstName()
    
    do {
      userProfile = try await SupabaseManager.shared.fetchUserProfile()
      
      // Map stored coaching style string to enum
      if let styleString = userProfile?.coachingStyle {
        selectedCoachingStyle = mapDatabaseToCoachingStyle(styleString)
      }
    } catch {
      print("❌ Failed to load profile: \(error)")
      errorMessage = "Failed to load profile"
    }
  }
  
  private func selectCoachingStyle(_ style: CoachingStyle) {
    guard selectedCoachingStyle != style else { return }
    
    let previousStyle = selectedCoachingStyle
    selectedCoachingStyle = style
    isSaving = true
    errorMessage = nil
    
    Task {
      do {
        try await SupabaseManager.shared.updateCoachingStyle(style)
        isSaving = false
      } catch {
        print("❌ Failed to update coaching style: \(error)")
        selectedCoachingStyle = previousStyle
        errorMessage = "Failed to save. Please try again."
        isSaving = false
      }
    }
  }
  
  private func signOut() {
    Task {
      do {
        try await SupabaseManager.shared.signOut()
        NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
        dismiss()
      } catch {
        print("❌ Sign out failed: \(error)")
        errorMessage = "Sign out failed. Please try again."
      }
    }
  }
  
  private func deleteAccount() {
    isDeleting = true
    errorMessage = nil
    
    Task {
      do {
        try await SupabaseManager.shared.deleteAccount()
        NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
        dismiss()
      } catch {
        print("❌ Delete account failed: \(error)")
        errorMessage = "Failed to delete account. Please try again."
        isDeleting = false
      }
    }
  }
  
  private func mapDatabaseToCoachingStyle(_ value: String) -> CoachingStyle? {
    switch value {
    case "direct": return .direct
    case "dataDriven": return .dataDriven
    case "encouraging": return .encouraging
    case "reflective": return .reflective
    default: return nil
    }
  }
}

// MARK: - Coaching Style Option

private struct CoachingStyleOption: View {
  let style: CoachingStyle
  let isSelected: Bool
  let isSaving: Bool
  let action: () -> Void
  
  private var selectedGradient: LinearGradient {
    LinearGradient(
      colors: [
        Color(red: 0.85, green: 0.93, blue: 1.0),
        Color(red: 0.72, green: 0.88, blue: 1.0)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
  
  var body: some View {
    Button(action: action) {
      HStack {
        Text(style.rawValue)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        
        Spacer()
        
        if isSaving {
          ProgressView()
            .scaleEffect(0.8)
        } else if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20))
            .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 14)
          .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(Color(red: 0.97, green: 0.97, blue: 0.98)))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(
            isSelected
              ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.5)
              : Color.clear,
            lineWidth: 1.5
          )
      )
    }
    .buttonStyle(.plain)
    .disabled(isSaving)
  }
}

#Preview {
  ProfileView()
}


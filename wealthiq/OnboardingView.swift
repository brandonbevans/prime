//
//  OnboardingView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SuperwallKit
import SwiftUI

struct OnboardingView: View {
  @StateObject private var viewModel = OnboardingViewModel()
  @State private var hasTriggeredPaywall = false
  @State private var showingErrorAlert = false
  @State private var showingDebugMenu = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        OnboardingBackground()

        VStack(spacing: 0) {
          // Debug sign out button
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

          OnboardingHeaderView(viewModel: viewModel)
            .padding(.top, 20)

          content
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

          Spacer(minLength: 0)

          if viewModel.currentStep != .gender
            && viewModel.currentStep != .goalRecency
            && viewModel.currentStep != .coachingStyle
            && viewModel.currentStep != .planCalculation
          {
            if viewModel.currentStep == .goalVisualization || viewModel.currentStep == .microAction
            {
              HStack(spacing: 12) {
                ContinueButtonView(
                  title: "Continue",
                  isEnabled: viewModel.canContinue
                ) {
                  handleContinue()
                }

                Button(action: {
                  viewModel.toggleVoiceRecording(for: viewModel.currentStep)
                }) {
                  Circle()
                    .fill(
                      viewModel.isRecording
                        ? Color(red: 0.39, green: 0.27, blue: 0.92)
                        : Color.white.opacity(0.98)
                    )
                    .overlay(
                      Image(
                        systemName: viewModel.isRecording ? "stop.fill" : "mic.fill"
                      )
                      .font(.system(size: 20))
                      .foregroundColor(
                        viewModel.isRecording
                          ? Color.white
                          : Color(red: 0.39, green: 0.27, blue: 0.92))
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                      Circle()
                        .stroke(
                          viewModel.isRecording
                            ? Color(red: 0.39, green: 0.27, blue: 0.92).opacity(0.3)
                            : Color(red: 0.93, green: 0.93, blue: 0.93),
                          lineWidth: viewModel.isRecording ? 2 : 1
                        )
                    )
                    .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                    .animation(
                      .easeInOut(duration: 0.2), value: viewModel.isRecording)
                }
              }
              .padding(.top, 24)
            } else {
              ContinueButtonView(
                title: "Continue",
                isEnabled: viewModel.canContinue
                  && (viewModel.currentStep != .planCalculation || !hasTriggeredPaywall)
              ) {
                handleContinue()
              }
              .padding(.top, 24)
            }
          }

          // Removed artificial home indicator - iOS provides its own
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)  // Reduced padding - iOS handles safe area
      }

      // Loading overlay
      if viewModel.isSaving {
        ZStack {
          Color.black.opacity(0.4)
            .ignoresSafeArea()

          VStack(spacing: 16) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(1.2)
              .tint(.white)

            Text("Saving your information...")
              .font(.outfit(16, weight: .medium))
              .foregroundColor(.white)
          }
          .padding(32)
          .background(Color(red: 0.13, green: 0.06, blue: 0.16))
          .cornerRadius(16)
        }
      }
    }
    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.currentStep)
    .animation(.easeInOut(duration: 0.2), value: viewModel.canContinue)
    .onChange(of: viewModel.currentStep) { newStep in
      if newStep != .planCalculation {
        hasTriggeredPaywall = false
      }
    }
    .alert("Error Saving Data", isPresented: $showingErrorAlert) {
      Button("OK", role: .cancel) {
        viewModel.saveError = nil
      }
    } message: {
      Text(
        viewModel.saveError?.localizedDescription
          ?? "An error occurred while saving your information. Please try again.")
    }
    .onReceive(viewModel.$saveError) { error in
      if error != nil {
        showingErrorAlert = true
      }
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
                  try await SupabaseManager.shared.signOut()
                  print("✅ Signed out successfully")
                  // Post notification to refresh auth state
                  NotificationCenter.default.post(name: .debugAuthCompleted, object: nil)
                } catch {
                  print("❌ Sign out failed: \(error)")
                }
              }
            },
            .destructive(Text("Force Sign Out & Clear Session")) {
              Task {
                do {
                  // Force sign out even if there's an error
                  try? await SupabaseManager.shared.signOut()

                  // Clear any stored session data
                  UserDefaults.standard.removeObject(forKey: "sb-auth-token")
                  UserDefaults.standard.synchronize()

                  print("✅ Force signed out and cleared session")
                }
              }
            },
            .default(Text("Check Session")) {
              Task {
                do {
                  let userId = try await SupabaseManager.shared.getCurrentUserId()
                  print("✅ Session valid - User ID: \(userId)")
                } catch {
                  print("❌ No valid session: \(error)")
                }
              }
            },
            .cancel(),
          ]
        )
      }
    #endif
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.currentStep {
    case .gender:
      GenderSelectionView(viewModel: viewModel)
    case .name:
      NameInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .age:
      AgeInputView(viewModel: viewModel)
    case .welcomeIntro:
      WelcomeIntroView(viewModel: viewModel)
    case .goalRecency:
      GoalRecencySelectionView(viewModel: viewModel) {
        handleContinue()
      }
    case .goalWritingInfo:
      GoalWritingInfoView()
    case .primaryGoal:
      PrimaryGoalInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .goalVisualization:
      GoalVisualizationInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .visualizationInfo:
      VisualizationInfoView()
    case .microAction:
      MicroActionInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .coachingStyle:
      CoachingStyleSelectionView(viewModel: viewModel)
    case .planCalculation:
      PlanCalculationView(viewModel: viewModel) {
        // Save onboarding data when plan calculation completes
        print("🎯 Plan calculation complete - triggering save")
        Task {
          print("🚀 Starting onboarding data save...")
          await viewModel.saveOnboardingData()
          print("💾 Save complete, showing paywall")

          // Post notification that onboarding is complete
          await MainActor.run {
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
          }

          showPaywall()
        }
      }
    }
  }

  private func handleContinue() {
    guard viewModel.canContinue else { return }

    switch viewModel.currentStep {
    case .gender:
      withAnimation {
        viewModel.nextStep()
      }
    case .name:
      withAnimation {
        viewModel.nextStep()
      }
    case .age:
      withAnimation {
        viewModel.nextStep()
      }
    case .welcomeIntro:
      withAnimation {
        viewModel.nextStep()
      }
    case .goalRecency:
      withAnimation {
        viewModel.nextStep()
      }
    case .goalWritingInfo:
      withAnimation {
        viewModel.nextStep()
      }
    case .primaryGoal:
      withAnimation {
        viewModel.nextStep()
      }
    case .goalVisualization:
      withAnimation {
        viewModel.nextStep()
      }
    case .visualizationInfo:
      withAnimation {
        viewModel.nextStep()
      }
    case .microAction:
      withAnimation {
        viewModel.nextStep()
      }
    case .coachingStyle:
      withAnimation {
        viewModel.nextStep()
      }
    case .planCalculation:
      // This case shouldn't be reached as planCalculation doesn't have a continue button
      break
    }
  }

  private func showPaywall() {
    guard !hasTriggeredPaywall else { return }
    hasTriggeredPaywall = true
    Superwall.shared.register(placement: "campaign_trigger")
  }
}

// MARK: - Background & Chrome

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
        core: Color(red: 1.0, green: 0.66, blue: 0.98),
        highlight: Color(red: 1.0, green: 0.81, blue: 0.99),
        glow: Color(red: 0.95, green: 0.77, blue: 1.0)
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
  OnboardingView()
}

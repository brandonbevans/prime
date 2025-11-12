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

  var body: some View {
    ZStack {
      OnboardingBackground()

      VStack(spacing: 0) {
        OnboardingHeaderView(viewModel: viewModel)
          .padding(.top, 64)

        content
          .padding(.top, 56)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 0)

        if viewModel.currentStep != .gender
          && viewModel.currentStep != .goalRecency
          && viewModel.currentStep != .coachingStyle
          && viewModel.currentStep != .processDifficulty
          && viewModel.currentStep != .planCalculation
        {
          ContinueButtonView(
            title: "Continue",
            isEnabled: viewModel.canContinue
              && (viewModel.currentStep != .planCalculation || !hasTriggeredPaywall)
          ) {
            handleContinue()
          }
          .padding(.top, 24)
        }

        HomeIndicatorView()
          .padding(.top, 11)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.currentStep)
    .animation(.easeInOut(duration: 0.2), value: viewModel.canContinue)
    .onChange(of: viewModel.currentStep) { newStep in
      if newStep != .planCalculation {
        hasTriggeredPaywall = false
      }
    }
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
    case .mood:
      MoodSelectionView(viewModel: viewModel)
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
    case .trajectoryFeeling:
      TrajectoryFeelingSelectionView(viewModel: viewModel)
    case .obstacles:
      ObstacleSelectionView(viewModel: viewModel)
    case .habitReplacement:
      HabitReplacementInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .deferredAction:
      DeferredActionInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .habitLawInfo:
      HabitLawInfoView()
    case .coachingStyle:
      CoachingStyleSelectionView(viewModel: viewModel)
    case .accountability:
      AccountabilityPreferenceSelectionView(viewModel: viewModel)
    case .motivationShift:
      MotivationShiftSelectionView(viewModel: viewModel)
    case .postSessionMood:
      PostSessionMoodSelectionView(viewModel: viewModel)
    case .processDifficulty:
      ProcessDifficultySelectionView(viewModel: viewModel)
    case .planCalculation:
      PlanCalculationView(viewModel: viewModel) {
        showPaywall()
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
    case .mood:
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
    case .trajectoryFeeling:
      withAnimation {
        viewModel.nextStep()
      }
    case .obstacles:
      withAnimation {
        viewModel.nextStep()
      }
    case .habitReplacement:
      withAnimation {
        viewModel.nextStep()
      }
    case .deferredAction:
      withAnimation {
        viewModel.nextStep()
      }
    case .habitLawInfo:
      withAnimation {
        viewModel.nextStep()
      }
    case .coachingStyle:
      withAnimation {
        viewModel.nextStep()
      }
    case .accountability:
      withAnimation {
        viewModel.nextStep()
      }
    case .motivationShift:
      withAnimation {
        viewModel.nextStep()
      }
    case .postSessionMood:
      withAnimation {
        viewModel.nextStep()
      }
    case .processDifficulty:
      withAnimation {
        viewModel.nextStep()
      }
    case .planCalculation:
      showPaywall()
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

private struct HomeIndicatorView: View {
  var body: some View {
    Capsule()
      .fill(Color.black.opacity(0.9))
      .frame(width: 108, height: 4)
  }
}

#Preview {
  OnboardingView()
}

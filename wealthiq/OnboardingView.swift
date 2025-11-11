//
//  OnboardingView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI

struct OnboardingView: View {
  @StateObject private var viewModel = OnboardingViewModel()
  @State private var hasCompleted = false

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

        if viewModel.currentStep != .gender {
          ContinueButtonView(
            title: "Continue",
            isEnabled: viewModel.canContinue
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
    .alert(
      "Onboarding Complete", isPresented: $hasCompleted,
      actions: {
        Button("OK", role: .cancel) {}
      },
      message: {
        Text("Great job! Hook this action up to the next screen when it's ready.")
      })
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
      GoalRecencySelectionView(viewModel: viewModel)
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
    case .commitment:
      CommitmentInputView(viewModel: viewModel) {
        handleContinue()
      }
    case .motivationShift:
      MotivationShiftSelectionView(viewModel: viewModel)
    case .postSessionMood:
      PostSessionMoodSelectionView(viewModel: viewModel)
    case .processDifficulty:
      ProcessDifficultySelectionView(viewModel: viewModel)
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
    case .commitment:
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
      hasCompleted = true
    }
  }
}

// MARK: - Background & Chrome

private struct OnboardingBackground: View {
  private enum AccentLocation {
    case top
    case bottom
  }

  private let topAccentURL = URL(
    string: "https://www.figma.com/api/mcp/asset/fe90c985-1450-4591-9523-58c4713640e8")
  private let bottomAccentURL = URL(
    string: "https://www.figma.com/api/mcp/asset/0580afcd-1f7a-4f75-9b86-0458db9bada6")

  var body: some View {
    Color.white
      .ignoresSafeArea()
      .overlay(
        AccentBlob(location: .top, url: topAccentURL)
          .frame(width: 198, height: 200)
          .offset(x: 325, y: 7),
        alignment: .topLeading
      )
      .overlay(
        AccentBlob(location: .bottom, url: bottomAccentURL)
          .frame(width: 268, height: 300)
          .offset(x: -202, y: 458),
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
    let location: AccentLocation
    let url: URL?

    var body: some View {
      Group {
        if let url {
          AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) {
            phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .scaledToFill()
            case .failure, .empty:
              fallbackGradient
            @unknown default:
              fallbackGradient
            }
          }
          .clipped()
        } else {
          fallbackGradient
        }
      }
      .clipShape(Ellipse())
      .opacity(location == .top ? 0.92 : 0.88)
    }

    private var fallbackGradient: some View {
      let gradient: LinearGradient
      switch location {
      case .top:
        gradient = LinearGradient(
          colors: [
            Color(red: 1.0, green: 0.74, blue: 0.99),
            Color.white.opacity(0.4),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      case .bottom:
        gradient = LinearGradient(
          colors: [
            Color(red: 0.66, green: 0.82, blue: 0.99),
            Color.white.opacity(0.35),
          ],
          startPoint: .bottomLeading,
          endPoint: .topTrailing
        )
      }
      return gradient
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

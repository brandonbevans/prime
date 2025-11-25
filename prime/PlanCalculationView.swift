//
//  PlanCalculationView.swift
//  prime
//
//  Created by ChatGPT on 11/12/25.
//

import SwiftUI

struct PlanCalculationView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onComplete: () -> Void

  private let animationDuration: TimeInterval = 10

  @State private var hasScheduledAdvance = false
  @State private var startTime: Date?
  @State private var isComplete = false
  @State private var currentStatusIndex = 0

  private let statusMessages = [
    "Analyzing your primary goal...",
    "Creating a personalized success track...",
    "Considering your preferred coaching style...",
    "Putting it all together...",
    "Finalizing your plan..."
  ]

  private let planItems = [
    "Goal Clarity",
    "Visualization Practice",
    "Micro-Actions",
    "Consistent Accountability",
    "Self-Esteem Growth"
  ]

  var body: some View {
    VStack(spacing: 0) {
      TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isComplete)) { timeline in
        let progress = calculateProgress(at: timeline.date)
        let displayedPercentage = Int(progress * 100)

        VStack(spacing: 0) {
          Spacer()
            .frame(height: 60)

          // Large percentage display
          Text("\(displayedPercentage)%")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.12, green: 0.1, blue: 0.16))
            .contentTransition(.numericText())

          // Headline
          Text(isComplete ? "Your Plan Is Ready!" : "We're setting\neverything up for you")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(Color(red: 0.12, green: 0.1, blue: 0.16))
            .multilineTextAlignment(.center)
            .padding(.top, 8)

          // Progress bar
          ProgressBarView(progress: progress)
            .frame(height: 10)
            .padding(.horizontal, 32)
            .padding(.top, 40)

          // Status text
          Text(isComplete ? "Complete!" : statusMessages[currentStatusIndex])
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.4, green: 0.38, blue: 0.45))
            .padding(.top, 16)

          Spacer()
            .frame(height: 48)

          // Card with plan items
          PlanItemsCard(items: planItems)
            .padding(.horizontal, 24)

          Spacer()
        }
      }

      // Get Started button - appears when complete
      if isComplete {
        ContinueButtonView(title: "Get Started", isEnabled: true) {
          onComplete()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.easeInOut(duration: 0.4), value: isComplete)
    .onAppear {
      startAnimationAndAdvance()
    }
    .onChange(of: viewModel.currentStep) {
      if viewModel.currentStep == .planCalculation {
        startAnimationAndAdvance()
      }
    }
  }

  private func calculateProgress(at date: Date) -> Double {
    guard let start = startTime else { return 0 }
    let elapsed = date.timeIntervalSince(start)
    let raw = elapsed / animationDuration
    // Ease-out curve for more natural feel
    let eased = 1 - pow(1 - min(raw, 1), 2)
    return eased
  }

  private func startAnimationAndAdvance() {
    guard !hasScheduledAdvance else { return }
    hasScheduledAdvance = true
    startTime = Date()
    isComplete = false
    currentStatusIndex = 0

    // Cycle through status messages
    let messageInterval = animationDuration / Double(statusMessages.count)
    for i in 0..<statusMessages.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + messageInterval * Double(i)) {
        guard viewModel.currentStep == .planCalculation else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
          currentStatusIndex = i
        }
      }
    }

    // Complete - show the Get Started button
    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
      guard viewModel.currentStep == .planCalculation else { return }
      withAnimation(.easeInOut(duration: 0.3)) {
        isComplete = true
      }
      hasScheduledAdvance = false
    }
  }
}

// MARK: - Progress Bar

private struct ProgressBarView: View {
  let progress: Double

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Background track
        Capsule()
          .fill(Color(red: 0.92, green: 0.92, blue: 0.94))

        // Filled portion with gradient
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.25, green: 0.42, blue: 0.96),
                Color(red: 0.45, green: 0.58, blue: 1.0)
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: max(geometry.size.width * progress, 10))
      }
    }
  }
}

// MARK: - Plan Items Card

private struct PlanItemsCard: View {
  let items: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Personal plan for")
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(Color(red: 0.12, green: 0.1, blue: 0.16))

      VStack(alignment: .leading, spacing: 10) {
        ForEach(items, id: \.self) { item in
          HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 14))
              .foregroundColor(Color(red: 0.25, green: 0.42, blue: 0.96))

            Text(item)
              .font(.system(size: 15))
              .foregroundColor(Color(red: 0.12, green: 0.1, blue: 0.16))
          }
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(red: 0.92, green: 0.92, blue: 0.94), lineWidth: 1)
    )
  }
}

#Preview {
  PlanCalculationView(viewModel: OnboardingViewModel(), onComplete: {})
    .background(Color(red: 0.98, green: 0.98, blue: 0.99))
}

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
  @State private var animationProgress: Double = 0
  @State private var isComplete = false

  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      HourglassIllustration(progress: animationProgress)
        .frame(width: 88, height: 88)
        .padding(.top, 4)

      VStack(alignment: .leading, spacing: 14) {
        Text(isComplete ? "Your Personal Plan Is Ready!" : "Calculating Your Plan…")
          .font(.lora(24, weight: .semiBold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))

        Text(
          isComplete
            ? "Your personal plan is ready. It's time to invest in yourself. In this app we'll raise your self-esteem, teach you how to tap into the superconscious, and turn your brain into a goal-achieving machine."
            : "Take a moment to reflect on how you're feeling in this very moment compared to when you started.\nDo you see how this process has lifted your spirits even just a little bit?\nThis is the power of visualization and goal setting at work.\nIt is a skill in of itself, and that was is what we'll continue to develop in the coming weeks."
        )
        .font(.outfit(16))
        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
        .lineSpacing(6)
        .multilineTextAlignment(.leading)

        Text("\(Int(animationProgress * 100))% complete")
          .font(.outfit(14, weight: .medium))
          .foregroundColor(Color(red: 0.36, green: 0.33, blue: 0.46))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      startAnimationAndAdvance()
    }
    .onChange(of: viewModel.currentStep) {
      if viewModel.currentStep == .planCalculation {
        startAnimationAndAdvance()
      }
    }
  }

  private func startAnimationAndAdvance() {
    guard !hasScheduledAdvance else { return }
    hasScheduledAdvance = true
    animationProgress = 0
    isComplete = false

    withAnimation(.linear(duration: animationDuration)) {
      animationProgress = 1
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
      guard viewModel.currentStep == .planCalculation else { return }
      isComplete = true
      onComplete()
      hasScheduledAdvance = false
    }
  }
}

private struct HourglassIllustration: View {
  let progress: Double

  private var rotationAngle: Angle {
    let phase = progress * .pi * 2
    let bounce = sin(phase)

    // Base: 2 full rotations over the animation (twice as fast as before)
    let baseRotations = 2.0

    // Speed up rotation as we approach the apex of the bounce (|bounce| -> 1)
    let speedFactor = 1.0 + 1.5 * abs(bounce)  // 1x to 2.5x

    let degrees = progress * baseRotations * 360 * speedFactor
    return .degrees(degrees)
  }

  private var bounceOffset: CGFloat {
    // Gentle bounce up and down over time
    let phase = progress * .pi * 2
    return -10 * CGFloat(sin(phase))
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.93, green: 0.89, blue: 1.0),
              Color(red: 0.83, green: 0.94, blue: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 28)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )

      VStack(spacing: 12) {
        HourglassShape()
          .stroke(Color(red: 0.33, green: 0.24, blue: 0.64), lineWidth: 3.5)
          .frame(width: 36, height: 48)
          .overlay(
            HourglassFill()
              .fill(Color(red: 0.41, green: 0.3, blue: 0.78))
              .frame(width: 28, height: 34)
              .offset(y: 6)
          )

        Capsule()
          .fill(Color(red: 0.56, green: 0.67, blue: 1.0).opacity(0.9))
          .frame(width: 42, height: 6)
      }
    }
    .rotationEffect(rotationAngle)
    .offset(y: bounceOffset)
  }
}

private struct HourglassShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let neckWidth = rect.width * 0.3
    let midY = rect.midY

    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX + neckWidth / 2, y: midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.midX - neckWidth / 2, y: midY))
    path.closeSubpath()
    return path
  }
}

private struct HourglassFill: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let midY = rect.midY

    path.move(to: CGPoint(x: rect.minX, y: midY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: midY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

#Preview {
  PlanCalculationView(viewModel: OnboardingViewModel(), onComplete: {})
    .padding(20)
    .background(Color.white)
}

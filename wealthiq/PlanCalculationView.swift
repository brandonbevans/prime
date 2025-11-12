//
//  PlanCalculationView.swift
//  wealthiq
//
//  Created by ChatGPT on 11/12/25.
//

import SwiftUI

struct PlanCalculationView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onComplete: () -> Void

  @State private var hasScheduledAdvance = false

  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      HourglassIllustration()
        .frame(width: 88, height: 88)
        .padding(.top, 4)

      VStack(alignment: .leading, spacing: 14) {
        Text("Calculating Your Plan…")
          .font(.outfit(24, weight: .semiBold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))

        Text("Look how even this onboarding has you feeling more ready to tackle your goals")
          .font(.outfit(16))
          .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
          .lineSpacing(4)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      scheduleAdvance()
    }
    .onChange(of: viewModel.currentStep) { _ in
      if viewModel.currentStep == .planCalculation {
        scheduleAdvance()
      }
    }
  }

  private func scheduleAdvance() {
    guard !hasScheduledAdvance else { return }
    hasScheduledAdvance = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      guard viewModel.currentStep == .planCalculation else { return }
      onComplete()
      hasScheduledAdvance = false
    }
  }
}

private struct HourglassIllustration: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.93, green: 0.89, blue: 1.0),
              Color(red: 0.83, green: 0.94, blue: 1.0)
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
  }
}

private struct HourglassShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let topWidth = rect.width
    let bottomWidth = rect.width
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
  PlanCalculationView(viewModel: OnboardingViewModel())
    .padding(20)
    .background(Color.white)
}


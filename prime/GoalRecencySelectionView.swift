//
//  GoalRecencySelectionView.swift
//  prime
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct GoalRecencySelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSelection: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("When was the last time you\nwrote down your goals?")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(spacing: 12) {
        ForEach(viewModel.goalRecencyOptions, id: \.self) { option in
          GoalRecencyChip(
            title: option.rawValue,
            isSelected: viewModel.selectedGoalRecency == option
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.selectGoalRecency(option)
            }
            onSelection()
          }
        }
      }
    }
  }
}

private struct GoalRecencyChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  private var selectedGradient: LinearGradient {
    LinearGradient(
      colors: [
        Color(red: 0.85, green: 0.93, blue: 1.0),
        Color(red: 0.72, green: 0.88, blue: 1.0),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
          RoundedRectangle(cornerRadius: 80)
            .fill(
              isSelected
                ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(Color.white.opacity(0.97)))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 80)
            .stroke(
              isSelected
                ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.7)
                : Color(red: 0.93, green: 0.93, blue: 0.93),
              lineWidth: 1
            )
        )
        .shadow(
          color: isSelected ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.18) : Color.clear,
          radius: 18,
          x: 0,
          y: 10
        )
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  GoalRecencySelectionView(viewModel: OnboardingViewModel())
    .padding(20)
    .background(Color.white)
}

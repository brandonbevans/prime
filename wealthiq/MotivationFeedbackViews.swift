//
//  MotivationFeedbackViews.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct MotivationShiftSelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("How do you feel now?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(spacing: 12) {
        ForEach(viewModel.motivationShiftOptions, id: \.rawValue) { shift in
          SelectionPill(
            title: shift.rawValue,
            isSelected: viewModel.motivationShift == shift
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.selectMotivationShift(shift)
            }
          }
        }
      }
    }
  }
}

struct PostSessionMoodSelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  private let columns: [GridItem] = Array(
    repeating: GridItem(.flexible(), spacing: 12),
    count: 3
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("How do you feel now?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
        ForEach(viewModel.moodOptions, id: \.self) { mood in
          GradientSelectableChip(
            title: mood.rawValue,
            isSelected: viewModel.postSessionMoods.contains(mood)
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.togglePostSessionMood(mood)
            }
          }
        }
      }
    }
  }
}

struct ProcessDifficultySelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("How difficult was this process for you?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(spacing: 12) {
        ForEach(viewModel.difficultyOptions, id: \.rawValue) { difficulty in
          SelectionPill(
            title: difficulty.rawValue,
            isSelected: viewModel.processDifficulty == difficulty
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.selectProcessDifficulty(difficulty)
            }
          }
        }
      }
    }
  }
}

private struct SelectionPill: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  private var selectedGradient: LinearGradient {
    LinearGradient(
      colors: [
        Color(red: 0.87, green: 0.79, blue: 1.0),
        Color(red: 0.78, green: 0.69, blue: 0.99)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.outfit(16, weight: .medium))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
          RoundedRectangle(cornerRadius: 80)
            .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(Color.white.opacity(0.97)))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 80)
            .stroke(
              isSelected
                ? Color(red: 0.52, green: 0.36, blue: 0.94).opacity(0.7)
                : Color(red: 0.93, green: 0.93, blue: 0.93),
              lineWidth: 1
            )
        )
        .shadow(
          color: isSelected ? Color(red: 0.4, green: 0.27, blue: 0.91).opacity(0.18) : Color.clear,
          radius: 18,
          x: 0,
          y: 10
        )
    }
    .buttonStyle(.plain)
  }
}



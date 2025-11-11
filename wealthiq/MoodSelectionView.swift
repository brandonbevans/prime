//
//  MoodSelectionView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct MoodSelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  private let columns: [GridItem] = Array(
    repeating: GridItem(.flexible(), spacing: 12),
    count: 3
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("How do you feel right now?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
        ForEach(viewModel.moodOptions, id: \.self) { mood in
          MoodChip(
            title: mood.rawValue,
            isSelected: viewModel.isMoodSelected(mood)
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.toggleMood(mood)
            }
          }
        }
      }
    }
  }
}

private struct MoodChip: View {
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
      HStack(spacing: 8) {
        Text(title)
          .font(.outfit(14, weight: .medium))
          .foregroundColor(isSelected ? Color(red: 0.13, green: 0.06, blue: 0.16) : Color(red: 0.2, green: 0.18, blue: 0.19))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        if isSelected {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        }
      }
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 80)
          .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(Color.white.opacity(0.97)))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 80)
          .stroke(
            isSelected ? Color(red: 0.52, green: 0.36, blue: 0.94).opacity(0.6) : Color(red: 0.93, green: 0.93, blue: 0.93),
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

#Preview {
  MoodSelectionView(viewModel: OnboardingViewModel())
    .padding(20)
    .background(Color.white)
}



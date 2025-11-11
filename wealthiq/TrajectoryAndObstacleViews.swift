//
//  TrajectoryAndObstacleViews.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct TrajectoryFeelingSelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  private let columns: [GridItem] = Array(
    repeating: GridItem(.flexible(), spacing: 12),
    count: 2
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("How do you feel about your current trajectory?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
        ForEach(viewModel.trajectoryOptions, id: \.rawValue) { feeling in
          GradientSelectableChip(
            title: feeling.rawValue,
            isSelected: viewModel.selectedTrajectoryFeelings.contains(feeling)
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.toggleTrajectoryFeeling(feeling)
            }
          }
        }
      }
    }
  }
}

struct ObstacleSelectionView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  private let columns: [GridItem] = Array(
    repeating: GridItem(.flexible(), spacing: 12),
    count: 2
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("What’s the single biggest obstacle in your way right now?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
        ForEach(viewModel.obstacleOptions) { obstacle in
          GradientSelectableChip(
            title: obstacle.rawValue,
            isSelected: viewModel.selectedObstacles.contains(obstacle)
          ) {
            withAnimation(.easeInOut(duration: 0.2)) {
              viewModel.toggleObstacle(obstacle)
            }
          }
        }
      }
    }
  }
}



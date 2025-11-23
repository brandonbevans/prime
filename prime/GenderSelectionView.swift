//
//  GenderSelectionView.swift
//  prime
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI

struct GenderSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What is your gender?")
        .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
                .multilineTextAlignment(.leading)
            
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    GenderChip(
            title: gender.rawValue,
            symbol: symbol(for: gender),
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        selectGender(gender)
                    }
                }
            }
        }
    }

    private func selectGender(_ gender: Gender) {
        guard viewModel.currentStep == .gender else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.selectedGender = gender
        }

        let advanceDelay: DispatchTimeInterval = .milliseconds(250)
        DispatchQueue.main.asyncAfter(deadline: .now() + advanceDelay) {
            guard self.viewModel.currentStep == .gender else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                self.viewModel.nextStep()
            }
        }
    }

  private func symbol(for gender: Gender) -> String {
    switch gender {
    case .female:
      return "♀"
    case .male:
      return "♂"
    }
  }
}

private struct GenderChip: View {
    let title: String
  let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
  private var selectedGradient: LinearGradient {
    LinearGradient(
      colors: [
        Color(red: 0.85, green: 0.93, blue: 1.0),
        Color(red: 0.72, green: 0.88, blue: 1.0)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

    var body: some View {
        Button(action: action) {
      HStack(spacing: 8) {
        Text(symbol)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color(red: 0.20, green: 0.18, blue: 0.19))

        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color(red: 0.20, green: 0.18, blue: 0.19))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 100)
          .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(Color.white.opacity(0.95)))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 100)
          .stroke(
            isSelected
              ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.7)
              : Color(red: 0.93, green: 0.93, blue: 0.93),
            lineWidth: 0.5
          )
      )
      .shadow(
        color: isSelected
          ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.18)
          : Color.clear,
        radius: 18,
        x: 0,
        y: 10
      )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GenderSelectionView(viewModel: OnboardingViewModel())
        .padding(20)
        .background(Color.white)
}


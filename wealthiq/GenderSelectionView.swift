//
//  GenderSelectionView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI

struct GenderSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What is your gender?")
                .font(.outfit(24, weight: .semiBold))
                .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
                .multilineTextAlignment(.leading)
            
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    GenderChip(
                        title: gender.rawValue,
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
}

private struct GenderChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.outfit(14, weight: .medium))
                .foregroundColor(isSelected ? Color.black : Color(red: 0.20, green: 0.18, blue: 0.19))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(isSelected ? Color(red: 0.93, green: 0.91, blue: 1.0) : Color.white.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(
                            isSelected
                                ? Color(red: 0.39, green: 0.27, blue: 0.92)
                                : Color(red: 0.93, green: 0.93, blue: 0.93),
                            lineWidth: isSelected ? 0.5 : 0.5
                        )
                )
                .shadow(
                    color: isSelected
                        ? Color(red: 0.40, green: 0.27, blue: 0.91).opacity(0.18)
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


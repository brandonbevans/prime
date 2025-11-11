//
//  OnboardingHeaderView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI

struct OnboardingHeaderView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.previousStep()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.outfit(16, weight: .semiBold))
                    .foregroundColor(Color(red: 0.26, green: 0.23, blue: 0.36))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .opacity(viewModel.currentStep == .gender ? 0 : 1)
            .disabled(viewModel.currentStep == .gender)
            .contentShape(Rectangle())
            
            Spacer(minLength: 16)
            
            ProgressIndicatorView(progress: viewModel.progress)
                .frame(width: 159, height: 4)
            
            Spacer(minLength: 16)
            
            Circle()
                .fill(Color.white.opacity(0.9))
                .overlay(
                    Text("\(viewModel.currentStep.rawValue + 1)")
                        .font(.outfit(14, weight: .semiBold))
                        .foregroundColor(Color(red: 0.32, green: 0.29, blue: 0.46))
                )
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(height: 24)
    }
}

struct ProgressIndicatorView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 112)
                    .fill(Color(red: 0.88, green: 0.89, blue: 0.89))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color(red: 0.39, green: 0.27, blue: 0.92))
                    .frame(width: max(geometry.size.width * progress, 7), height: 4)
            }
            .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingHeaderView(viewModel: OnboardingViewModel())
        ProgressIndicatorView(progress: 0.5)
    }
    .padding()
    .background(Color.white)
}


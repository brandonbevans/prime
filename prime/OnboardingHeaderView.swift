//
//  OnboardingHeaderView.swift
//  prime
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.26, green: 0.23, blue: 0.36))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .opacity(viewModel.currentStep == .welcomeIntro ? 0 : 1)
            .disabled(viewModel.currentStep == .welcomeIntro)
            .contentShape(Rectangle())
            
            Spacer(minLength: 16)
            
            ProgressIndicatorView(progress: viewModel.progress)
                .frame(width: 159, height: 4)
            
            Spacer(minLength: 16)
            
            // Spacer to balance the chevron on the left, keeping progress centered if desired,
            // or just remove the right element. Since the design screenshot shows just the bar,
            // we can use an invisible placeholder or just let the spacer handle it.
            // To keep the back button and progress bar aligned as in the design (centered bar?),
            // we might want a dummy view of the same size as the back button if we want perfect centering.
            // For now, just an invisible frame to balance the layout if needed, or simply nothing.
            Color.clear
                .frame(width: 24, height: 24)
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
                    .fill(Color.black)
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


//
//  NameInputView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI

struct NameInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onSubmit: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What's your first name?")
                .font(.outfit(24, weight: .semiBold))
                .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
                .multilineTextAlignment(.leading)
            
            RoundedRectangle(cornerRadius: 80)
                .fill(Color.white.opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 80)
                        .stroke(Color(red: 0.93, green: 0.93, blue: 0.93), lineWidth: 1)
                )
                .frame(height: 56)
                .overlay(
                    TextField(
                        "",
                        text: $viewModel.firstName,
                        prompt: Text("e.g. John")
                            .font(.outfit(14))
                            .foregroundColor(Color(red: 0.73, green: 0.67, blue: 0.75))
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(.outfit(14))
                    .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
                    .padding(.horizontal, 24)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)
                )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    NameInputView(viewModel: OnboardingViewModel(), onSubmit: {})
        .padding(20)
        .background(Color.white)
}


//
//  AgeInputView.swift
//  prime
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct AgeInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  @FocusState private var isTextFieldFocused: Bool

  private var ageBinding: Binding<String> {
    Binding(
      get: { viewModel.age },
      set: { newValue in
        let filteredScalars = newValue.unicodeScalars.filter {
          CharacterSet.decimalDigits.contains($0)
        }
        let digitsOnly = String(String.UnicodeScalarView(filteredScalars))
        let limited = String(digitsOnly.prefix(3))
        if viewModel.age != limited {
          viewModel.age = limited
        }
      }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("What is your age?")
        .font(.system(size: 24, weight: .semibold))
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
          HStack(spacing: 8) {
            TextField(
              "",
              text: ageBinding,
              prompt: Text("27")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.73, green: 0.67, blue: 0.75))
            )
            .autocorrectionDisabled()
            .keyboardType(.numberPad)
            .font(.system(size: 14))
            .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
            .focused($isTextFieldFocused)

            Text("Years")
              .font(.system(size: 14))
              .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16).opacity(0.7))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 24)
        )
    }
  }
}

#Preview {
  AgeInputView(viewModel: OnboardingViewModel())
    .padding(20)
    .background(Color.white)
}

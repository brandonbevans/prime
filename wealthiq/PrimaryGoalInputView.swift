//
//  PrimaryGoalInputView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct PrimaryGoalInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @State private var isEditorFocused = false
  private let placeholderText = "(e.g. making $10k/month, losing 20 pounds, finding a partner)"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("What is your #1 goal in life right now?")
          .font(.lora(24, weight: .semiBold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(
          "If you don't know immediately, that's okay. Take 2 minutes to think about it, and write down what you come up with."
        )
        .font(.outfit(14))
        .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
        .multilineTextAlignment(.leading)
        .lineSpacing(6)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)

        GoalEditorContainer {
          OnboardingTextArea(
            text: $viewModel.primaryGoal,
            placeholder: placeholderText,
            isFocused: Binding(
              get: { isEditorFocused },
              set: { isEditorFocused = $0 }
            )
          )
          .frame(height: 100)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
      }
      .padding(.bottom, 20)
    }
    .scrollDismissesKeyboard(.never)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        isEditorFocused = true
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
          isEditorFocused = false
          onSubmit()
        }
        .font(.outfit(16, weight: .medium))
      }
    }
  }
}

private struct GoalEditorContainer<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(Color.white.opacity(0.98))
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color(red: 0.93, green: 0.93, blue: 0.93), lineWidth: 1)
      )
      .overlay(
        content
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
      )
      .clipShape(RoundedRectangle(cornerRadius: 24))
  }
}

#Preview {
  PrimaryGoalInputView(viewModel: OnboardingViewModel(), onSubmit: {})
    .padding(20)
    .background(Color.white)
}

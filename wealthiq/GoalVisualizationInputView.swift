//
//  GoalVisualizationInputView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct GoalVisualizationInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @FocusState private var isEditorFocused: Bool
  private let placeholderText = "Share thoughts"

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 10) {
        Text("Stop and imagine what it would feel like to accomplish this goal.")
          .font(.outfit(24, weight: .semiBold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        Text("What would be different?")
          .font(.outfit(24, weight: .semiBold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
      }
      .multilineTextAlignment(.leading)

      GoalReflectionEditor {
        ZStack(alignment: .topLeading) {
          if viewModel.goalVisualization.isEmpty {
            Text(placeholderText)
              .font(.outfit(14))
              .foregroundColor(Color(red: 0.67, green: 0.62, blue: 0.72))
              .padding(.horizontal, 16)
              .padding(.vertical, 18)
          }

          TextEditor(text: $viewModel.goalVisualization)
            .font(.outfit(14))
            .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
            .autocorrectionDisabled(false)
            .textInputAutocapitalization(.sentences)
            .focused($isEditorFocused)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.clear)
            .scrollContentBackground(.hidden)
        }
        .frame(height: 140)
      }
    }
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

private struct GoalReflectionEditor<Content: View>: View {
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
  }
}

#Preview {
  GoalVisualizationInputView(viewModel: OnboardingViewModel(), onSubmit: {})
    .padding(20)
    .background(Color.white)
}



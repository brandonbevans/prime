//
//  MicroActionInputView.swift
//  prime
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct MicroActionInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @State private var isEditorFocused = false
  @State private var isRecording = false
  private let placeholderText = "One tiny, concrete action."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("How could you make 1% progress toward your goal?")
          .font(.system(size: 24, weight: .semibold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)

        MicroActionEditor {
          OnboardingTextArea(
            text: $viewModel.microAction,
            placeholder: placeholderText,
            isFocused: $isEditorFocused
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
        .font(.system(size: 16, weight: .medium))
      }
    }
  }
}

private struct MicroActionEditor<Content: View>: View {
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
  MicroActionInputView(viewModel: OnboardingViewModel(), onSubmit: {})
    .padding(20)
    .background(Color.white)
}

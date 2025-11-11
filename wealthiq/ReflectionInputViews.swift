//
//  ReflectionInputViews.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct HabitReplacementInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @FocusState private var isEditorFocused: Bool
  private let placeholder = "Share thoughts"

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("What’s one habit you need to quit or replace?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      ReflectionEditorContainer {
        ZStack(alignment: .topLeading) {
          if viewModel.habitToReplace.isEmpty {
            placeholderView
          }

          editor(text: $viewModel.habitToReplace)
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

  private var placeholderView: some View {
    Text(placeholder)
      .font(.outfit(14))
      .foregroundColor(Color(red: 0.67, green: 0.62, blue: 0.72))
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
  }

  private func editor(text: Binding<String>) -> some View {
    TextEditor(text: text)
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
}

struct DeferredActionInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @FocusState private var isEditorFocused: Bool
  private let placeholder = "Share thoughts"

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("What is one thing you know you should be doing—but haven’t been?")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      ReflectionEditorContainer {
        ZStack(alignment: .topLeading) {
          if viewModel.deferredAction.isEmpty {
            placeholderView
          }

          editor(text: $viewModel.deferredAction)
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

  private var placeholderView: some View {
    Text(placeholder)
      .font(.outfit(14))
      .foregroundColor(Color(red: 0.67, green: 0.62, blue: 0.72))
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
  }

  private func editor(text: Binding<String>) -> some View {
    TextEditor(text: text)
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
}

struct CommitmentInputView: View {
  @ObservedObject var viewModel: OnboardingViewModel
  var onSubmit: () -> Void

  @FocusState private var isEditorFocused: Bool
  private let placeholder = "One action you’ll complete in the next day to create momentum."

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Let’s make a\n24-hour commitment")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      ReflectionEditorContainer {
        ZStack(alignment: .topLeading) {
          if viewModel.commitmentAction.isEmpty {
            placeholderView
          }

          editor(text: $viewModel.commitmentAction)
            .frame(height: 120)
        }
      }

      Toggle(isOn: $viewModel.shouldRemindIn24h) {
        Text("Remind me in 24h")
          .font(.outfit(16))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
      }
      .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.24, green: 0.88, blue: 0.64)))
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

  private var placeholderView: some View {
    Text(placeholder)
      .font(.outfit(14))
      .foregroundColor(Color(red: 0.67, green: 0.62, blue: 0.72))
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
  }

  private func editor(text: Binding<String>) -> some View {
    TextEditor(text: text)
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
}

private struct ReflectionEditorContainer<Content: View>: View {
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



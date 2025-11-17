//
//  OnboardingTextArea.swift
//  wealthiq
//
//  Created by ChatGPT on 11/12/25.
//

import SwiftUI

#if canImport(UIKit)
  import UIKit

  struct OnboardingTextArea: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFocused: Binding<Bool>
    var autocapitalization: UITextAutocapitalizationType
    var autocorrection: UITextAutocorrectionType

    init(
      text: Binding<String>,
      placeholder: String,
      isFocused: Binding<Bool>,
      autocapitalization: UITextAutocapitalizationType = .sentences,
      autocorrection: UITextAutocorrectionType = .default
    ) {
      self._text = text
      self.placeholder = placeholder
      self.isFocused = isFocused
      self.autocapitalization = autocapitalization
      self.autocorrection = autocorrection
    }

    func makeCoordinator() -> Coordinator {
      Coordinator(text: $text, isFocused: isFocused)
    }

    func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
      textView.delegate = context.coordinator
      textView.backgroundColor = .clear
      textView.font = Self.font
      textView.textColor = Self.textColor
      textView.autocapitalizationType = autocapitalization
      textView.autocorrectionType = autocorrection
      textView.keyboardDismissMode = .interactive
      textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
      textView.textContainer.lineFragmentPadding = 0
      textView.adjustsFontForContentSizeCategory = true
      textView.showsVerticalScrollIndicator = false
      textView.alwaysBounceVertical = false
      textView.isScrollEnabled = false
      textView.contentInsetAdjustmentBehavior = .never

      let placeholderLabel = context.coordinator.placeholderLabel
      placeholderLabel.text = placeholder
      placeholderLabel.font = Self.placeholderFont
      placeholderLabel.textColor = Self.placeholderColor
      placeholderLabel.numberOfLines = 0
      placeholderLabel.lineBreakMode = .byWordWrapping
      placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
      placeholderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      textView.addSubview(placeholderLabel)
      textView.sendSubviewToBack(placeholderLabel)

      let insets = textView.textContainerInset
      let padding = textView.textContainer.lineFragmentPadding

      NSLayoutConstraint.activate([
        placeholderLabel.leadingAnchor.constraint(
          equalTo: textView.leadingAnchor,
          constant: insets.left + padding
        ),
        placeholderLabel.trailingAnchor.constraint(
          lessThanOrEqualTo: textView.trailingAnchor,
          constant: -(insets.right + padding)
        ),
        placeholderLabel.topAnchor.constraint(
          equalTo: textView.topAnchor,
          constant: insets.top
        ),
        placeholderLabel.bottomAnchor.constraint(
          lessThanOrEqualTo: textView.bottomAnchor,
          constant: -insets.bottom
        ),
      ])

      // Set initial preferredMaxLayoutWidth for placeholder
      DispatchQueue.main.async {
        let availableWidth = textView.bounds.width - insets.left - insets.right - (padding * 2)
        if availableWidth > 0 {
          placeholderLabel.preferredMaxLayoutWidth = availableWidth
        }
      }

      context.coordinator.configure(textView: textView)
      context.coordinator.updatePlaceholderVisibility(for: text)
      Self.clampContentOffsetIfNeeded(textView)

      return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
      if textView.text != text {
        textView.text = text
      }

      if context.coordinator.placeholderLabel.text != placeholder {
        context.coordinator.placeholderLabel.text = placeholder
      }

      if textView.autocapitalizationType != autocapitalization {
        textView.autocapitalizationType = autocapitalization
      }

      if textView.autocorrectionType != autocorrection {
        textView.autocorrectionType = autocorrection
      }

      // Calculate available width for placeholder wrapping
      let insets = textView.textContainerInset
      let padding = textView.textContainer.lineFragmentPadding
      let availableWidth = textView.bounds.width - insets.left - insets.right - (padding * 2)
      if availableWidth > 0 {
        context.coordinator.placeholderLabel.preferredMaxLayoutWidth = availableWidth
      }

      context.coordinator.updatePlaceholderVisibility(for: text)

      // Force content offset to always be at top
      textView.contentOffset = .zero

      DispatchQueue.main.async {
        if isFocused.wrappedValue && !textView.isFirstResponder {
          textView.becomeFirstResponder()
        } else if !isFocused.wrappedValue && textView.isFirstResponder {
          textView.resignFirstResponder()
        }
      }
    }
  }

  extension OnboardingTextArea {
    final class Coordinator: NSObject, UITextViewDelegate {
      var text: Binding<String>
      var isFocused: Binding<Bool>
      let placeholderLabel = UILabel()
      private(set) weak var textView: UITextView?

      init(text: Binding<String>, isFocused: Binding<Bool>) {
        self.text = text
        self.isFocused = isFocused
      }

      func configure(textView: UITextView) {
        self.textView = textView
        if textView.text.isEmpty && textView.text != text.wrappedValue {
          textView.text = text.wrappedValue
        }
        updatePlaceholderVisibility(for: text.wrappedValue)
      }

      func textViewDidChange(_ textView: UITextView) {
        let newText = textView.text ?? ""

        if text.wrappedValue != newText {
          Task { @MainActor [weak self] in
            self?.text.wrappedValue = newText
          }
        }

        updatePlaceholderVisibility(for: newText)
        textView.contentOffset = .zero
      }

      func textViewDidBeginEditing(_ textView: UITextView) {
        if !isFocused.wrappedValue {
          Task { @MainActor [weak self] in
            guard let self else { return }
            if !self.isFocused.wrappedValue {
              self.isFocused.wrappedValue = true
            }
          }
        }
        updatePlaceholderVisibility(for: textView.text)
        textView.contentOffset = .zero
      }

      func textViewDidEndEditing(_ textView: UITextView) {
        if isFocused.wrappedValue {
          Task { @MainActor [weak self] in
            guard let self else { return }
            if self.isFocused.wrappedValue {
              self.isFocused.wrappedValue = false
            }
          }
        }
        updatePlaceholderVisibility(for: textView.text)
        textView.contentOffset = .zero
      }

      func updatePlaceholderVisibility(for text: String) {
        placeholderLabel.isHidden = !text.isEmpty
      }
    }
  }

  extension OnboardingTextArea {
    fileprivate static let font: UIFont = {
      if let customFont = UIFont(name: "Outfit-Regular", size: 14) {
        return customFont
      } else {
        return UIFont.systemFont(ofSize: 14, weight: .regular)
      }
    }()

    fileprivate static let textColor = UIColor(red: 0.13, green: 0.06, blue: 0.16, alpha: 1.0)
    fileprivate static let placeholderColor = UIColor(
      red: 0.67, green: 0.62, blue: 0.72, alpha: 1.0)
    fileprivate static let placeholderFont: UIFont = {
      if let customFont = UIFont(name: "Outfit-Regular", size: 14) {
        return customFont
      } else {
        return UIFont.systemFont(ofSize: 14, weight: .regular)
      }
    }()

    fileprivate static func clampContentOffsetIfNeeded(_ textView: UITextView) {
      // Always keep the content offset at or above the top so the cursor
      // doesn't drift upward when the keyboard appears.
      if textView.contentOffset.y < 0 {
        textView.setContentOffset(.zero, animated: false)
      }
    }
  }

#else

  struct OnboardingTextArea: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Binding<Bool>

    init(
      text: Binding<String>,
      placeholder: String,
      isFocused: Binding<Bool>
    ) {
      self._text = text
      self.placeholder = placeholder
      self.isFocused = isFocused
    }

    init(
      text: Binding<String>,
      placeholder: String,
      focusState: FocusState<Bool>.Binding
    ) {
      self._text = text
      self.placeholder = placeholder
      self.isFocused = Binding(
        get: { focusState.wrappedValue },
        set: { focusState.wrappedValue = $0 }
      )
    }

    var body: some View {
      TextEditor(text: $text)
        .overlay(alignment: .topLeading) {
          if text.isEmpty {
            Text(placeholder)
              .foregroundColor(Color(red: 0.67, green: 0.62, blue: 0.72))
              .padding(.horizontal, 12)
              .padding(.vertical, 12)
          }
        }
    }
  }

#endif

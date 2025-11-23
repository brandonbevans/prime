//
//  WelcomeIntroView.swift
//  prime
//
//  Created by Cursor on 11/16/25.
//

import SwiftUI

struct WelcomeIntroView: View {
  @ObservedObject var viewModel: OnboardingViewModel

  private var greetingText: String {
    let trimmedName = viewModel.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedName.isEmpty {
      return "Nice to meet you!"
    } else {
      return "Nice to meet you, \(trimmedName)!"
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 16) {
        Text("👋")
          .font(.system(size: 40))

        Text(greetingText)
          .font(.system(size: 24, weight: .semibold))
          .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
          .multilineTextAlignment(.leading)
      }

      VStack(alignment: .leading, spacing: 14) {
        Text(
          "You are about to embark on a journey where you'll be given the tools and knowledge to get what you want out of life."
        )
        Text(
          "There is no silver bullet to success. In all cases it requires sacrifice, discipline, and self-discovery. prime will give you the most modern, clinically backed tools to help you break down the barriers between you and the life of your dreams."
        )
        Text(
          "It will take about 10 minutes to get started. You'll need a quiet place to think, listen, and speak."
        )
      }
      .font(.system(size: 14))
      .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
      .multilineTextAlignment(.leading)
      .lineSpacing(6)
    }
  }
}

#Preview {
  WelcomeIntroView(viewModel: OnboardingViewModel())
    .padding(20)
    .background(Color.white)
}

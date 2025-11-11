//
//  HabitLawInfoView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct HabitLawInfoView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      HabitLawIllustrationView()
        .frame(width: 160, height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Breaking Habits with\nthe Law of Substitution")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(alignment: .leading, spacing: 14) {
        Text("The Law of Substitution says you can’t extinguish a bad habit; you can only replace it with a better one.")
        Text("Trying merely to suppress an unwanted habit leaves a void, but swapping in a positive routine leverages your brain’s habit loops instead of fighting them. You can’t focus on a negative behavior while you’re busy executing a positive one – your conscious mind can only hold one thought at a time, so the new habit crowds out the old.")
        Text("This strategy rewires the habit pattern, making change stick far better than just using willpower to “stop” the old behavior.")
      }
      .font(.outfit(14))
      .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
      .lineSpacing(6)
    }
  }
}

private struct HabitLawIllustrationView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.90, green: 0.86, blue: 1.0),
              Color(red: 0.82, green: 0.92, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 28)
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )

      VStack(spacing: 12) {
        Image(systemName: "brain.head.profile")
          .font(.system(size: 32, weight: .medium))
          .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.67))

        HStack(spacing: 12) {
          Capsule()
            .fill(Color(red: 0.75, green: 0.65, blue: 0.98).opacity(0.9))
            .frame(width: 36, height: 6)
          Capsule()
            .fill(Color(red: 0.62, green: 0.74, blue: 0.99).opacity(0.9))
            .frame(width: 36, height: 6)
        }
      }
    }
  }
}

#Preview {
  HabitLawInfoView()
    .padding(20)
    .background(Color.white)
}



//
//  GoalWritingInfoView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct GoalWritingInfoView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      GoalWritingIllustrationView()
        .frame(width: 160, height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("The Power of\nWriting Down Goals")
        .font(.outfit(24, weight: .semiBold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(alignment: .leading, spacing: 14) {
        Text("""
Less than 3% of people ever commit their goals to paper, and that tiny minority tends to achieve far more than everyone else.
""")
        Text("""
Putting a goal in writing transforms a vague wish into a clear target and signals to your brain that this outcome truly matters.
""")
        Text("""
It engages your mind’s built-in goal-seeking mechanism, intensifying your focus and motivation. In fact, simply writing down what you want makes you significantly more likely to achieve it.
""")
      }
      .font(.outfit(14))
      .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
      .multilineTextAlignment(.leading)
      .lineSpacing(6)
    }
  }
}

private struct GoalWritingIllustrationView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.9, green: 0.86, blue: 1.0),
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
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white.opacity(0.9))
          .frame(width: 108, height: 48)
          .overlay(
            Image(systemName: "pencil.and.outline")
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(Color(red: 0.38, green: 0.28, blue: 0.68))
          )

        Capsule()
          .fill(Color(red: 0.62, green: 0.74, blue: 0.99).opacity(0.9))
          .frame(width: 64, height: 6)
      }
    }
  }
}

#Preview {
  GoalWritingInfoView()
    .padding(20)
    .background(Color.white)
}



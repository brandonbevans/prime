//
//  VisualizationInfoView.swift
//  prime
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct VisualizationInfoView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      VisualizationIllustrationView()
        .frame(width: 160, height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Programming Your\nMind Through Visualization")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(Color(red: 0.13, green: 0.06, blue: 0.16))
        .multilineTextAlignment(.leading)

      VStack(alignment: .leading, spacing: 14) {
        Text("Your mind can’t tell the difference between a real experience and one you vividly imagine.")
        Text("When you visualize yourself accomplishing a goal, you’re literally programming your brain and body for success – firing the same neural circuits you’d use if it were happening for real.")
        Text("This kind of mental rehearsal is so effective that it’s a staple for elite performers – nearly all Olympic athletes use visualization to boost their confidence and performance before the real competition.")
      }
      .font(.system(size: 14))
      .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
      .lineSpacing(6)
    }
  }
}

private struct VisualizationIllustrationView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.90, green: 0.86, blue: 1.0),
              Color(red: 0.84, green: 0.90, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 28)
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )

      VStack(spacing: 6) {
        Image(systemName: "figure.mind.and.body")
          .font(.system(size: 32, weight: .medium))
          .foregroundColor(Color(red: 0.36, green: 0.25, blue: 0.67))
        HStack(spacing: 8) {
          Capsule()
            .fill(Color(red: 0.62, green: 0.74, blue: 0.99).opacity(0.9))
            .frame(width: 28, height: 6)
          Capsule()
            .fill(Color(red: 0.75, green: 0.65, blue: 0.98).opacity(0.9))
            .frame(width: 28, height: 6)
          Capsule()
            .fill(Color(red: 0.83, green: 0.72, blue: 0.98).opacity(0.9))
            .frame(width: 28, height: 6)
        }
      }
    }
  }
}

#Preview {
  VisualizationInfoView()
    .padding(20)
    .background(Color.white)
}



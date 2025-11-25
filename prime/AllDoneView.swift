//
//  AllDoneView.swift
//  prime
//
//  Created on 11/24/25.
//

import SwiftUI

struct AllDoneView: View {
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      // Celebration illustration
      CelebrationIllustration()
        .frame(width: 220, height: 220)
      
      // "All done!" badge
      HStack(spacing: 6) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 20))
          .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.35))
        
        Text("All done!")
          .font(.system(size: 17, weight: .medium))
          .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.32))
      }
      .padding(.top, 8)
      
      // Main heading
      Text("Time to generate\nyour custom plan!")
        .font(.system(size: 32, weight: .bold))
        .foregroundColor(Color(red: 0.08, green: 0.05, blue: 0.12))
        .multilineTextAlignment(.center)
        .lineSpacing(4)
      
      Spacer()
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Celebration Illustration

private struct CelebrationIllustration: View {
  @State private var isAnimating = false
  @State private var sparklePhase: Double = 0
  
  var body: some View {
    ZStack {
      // Outer gradient ring
      Circle()
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [
              Color(red: 0.95, green: 0.85, blue: 0.9),
              Color(red: 0.85, green: 0.9, blue: 1.0),
              Color(red: 0.9, green: 0.85, blue: 0.95),
              Color(red: 0.95, green: 0.85, blue: 0.9)
            ]),
            center: .center
          ),
          lineWidth: 12
        )
        .frame(width: 200, height: 200)
      
      // Inner white circle
      Circle()
        .fill(
          RadialGradient(
            gradient: Gradient(colors: [
              Color.white,
              Color(red: 0.98, green: 0.97, blue: 0.99)
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 90
          )
        )
        .frame(width: 180, height: 180)
      
      // Sparkles around the circle
      ForEach(0..<12, id: \.self) { index in
        SparkleView(delay: Double(index) * 0.15, phase: sparklePhase)
          .offset(sparkleOffset(for: index, in: 95))
      }
      
      // Hand heart gesture
      HandHeartGesture()
        .frame(width: 100, height: 120)
    }
    .onAppear {
      withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
        sparklePhase = 1
      }
    }
  }
  
  private func sparkleOffset(for index: Int, in radius: CGFloat) -> CGSize {
    let angle = (Double(index) / 12.0) * 2 * .pi - .pi / 2
    let x = cos(angle) * Double(radius)
    let y = sin(angle) * Double(radius)
    return CGSize(width: x, height: y)
  }
}

// MARK: - Sparkle View

private struct SparkleView: View {
  let delay: Double
  let phase: Double
  
  @State private var opacity: Double = 0.3
  @State private var scale: CGFloat = 0.6
  
  var body: some View {
    Circle()
      .fill(Color(red: 0.25, green: 0.2, blue: 0.35))
      .frame(width: 4, height: 4)
      .opacity(opacity)
      .scaleEffect(scale)
      .onAppear {
        withAnimation(
          .easeInOut(duration: 1.2)
          .repeatForever(autoreverses: true)
          .delay(delay)
        ) {
          opacity = 0.9
          scale = 1.0
        }
      }
  }
}

// MARK: - Hand Heart Gesture

private struct HandHeartGesture: View {
  @State private var floatOffset: CGFloat = 0
  
  var body: some View {
    ZStack {
      // Small heart above fingers
      HeartShape()
        .fill(Color(red: 0.9, green: 0.35, blue: 0.4))
        .frame(width: 18, height: 16)
        .offset(x: 8, y: -48 + floatOffset * 0.5)
      
      // Hand illustration
      HandShape()
        .stroke(Color(red: 0.15, green: 0.12, blue: 0.2), lineWidth: 2.5)
        .frame(width: 70, height: 90)
      
      // Wrist cuff
      WristCuff()
        .fill(Color(red: 0.15, green: 0.12, blue: 0.2))
        .frame(width: 40, height: 20)
        .offset(y: 50)
    }
    .offset(y: floatOffset)
    .onAppear {
      withAnimation(
        .easeInOut(duration: 2.5)
        .repeatForever(autoreverses: true)
      ) {
        floatOffset = -4
      }
    }
  }
}

// MARK: - Shapes

private struct HeartShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.width
    let height = rect.height
    
    path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
    
    // Left curve
    path.addCurve(
      to: CGPoint(x: width * 0.5, y: height),
      control1: CGPoint(x: 0, y: 0),
      control2: CGPoint(x: 0, y: height * 0.65)
    )
    
    // Right curve
    path.addCurve(
      to: CGPoint(x: width * 0.5, y: height * 0.25),
      control1: CGPoint(x: width, y: height * 0.65),
      control2: CGPoint(x: width, y: 0)
    )
    
    return path
  }
}

private struct HandShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height
    
    // Thumb and index finger forming heart shape
    // Start at bottom left of hand
    path.move(to: CGPoint(x: w * 0.2, y: h * 0.85))
    
    // Left side of palm
    path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.6))
    
    // Thumb going up
    path.addQuadCurve(
      to: CGPoint(x: w * 0.35, y: h * 0.15),
      control: CGPoint(x: w * 0.1, y: h * 0.35)
    )
    
    // Thumb tip curve
    path.addQuadCurve(
      to: CGPoint(x: w * 0.5, y: h * 0.22),
      control: CGPoint(x: w * 0.42, y: h * 0.08)
    )
    
    // Index finger tip curve
    path.addQuadCurve(
      to: CGPoint(x: w * 0.65, y: h * 0.15),
      control: CGPoint(x: w * 0.58, y: h * 0.08)
    )
    
    // Index finger down
    path.addQuadCurve(
      to: CGPoint(x: w * 0.85, y: h * 0.6),
      control: CGPoint(x: w * 0.9, y: h * 0.35)
    )
    
    // Right side of palm
    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.85))
    
    // Folded fingers (bumps)
    path.addQuadCurve(
      to: CGPoint(x: w * 0.65, y: h * 0.75),
      control: CGPoint(x: w * 0.72, y: h * 0.72)
    )
    path.addQuadCurve(
      to: CGPoint(x: w * 0.5, y: h * 0.78),
      control: CGPoint(x: w * 0.58, y: h * 0.72)
    )
    path.addQuadCurve(
      to: CGPoint(x: w * 0.35, y: h * 0.75),
      control: CGPoint(x: w * 0.42, y: h * 0.72)
    )
    path.addQuadCurve(
      to: CGPoint(x: w * 0.2, y: h * 0.85),
      control: CGPoint(x: w * 0.28, y: h * 0.72)
    )
    
    return path
  }
}

private struct WristCuff: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height
    
    // Simple rectangular cuff with rounded corners
    path.addRoundedRect(
      in: CGRect(x: 0, y: 0, width: w, height: h),
      cornerSize: CGSize(width: 4, height: 4)
    )
    
    // Add horizontal lines for texture
    path.move(to: CGPoint(x: w * 0.15, y: h * 0.35))
    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.35))
    
    path.move(to: CGPoint(x: w * 0.15, y: h * 0.65))
    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.65))
    
    return path
  }
}

#Preview {
  AllDoneView()
    .background(Color.white)
}


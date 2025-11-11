//
//  ContinueButtonView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI

struct ContinueButtonView: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 34.7)
                    .fill(buttonBackground)
                    .opacity(isEnabled ? 1 : 0.45)
                    .frame(height: 56)
                    .shadow(
                        color: Color(red: 0.22, green: 0.15, blue: 0.44).opacity(isEnabled ? 0.35 : 0.0),
                        radius: 24,
                        x: 0,
                        y: 12
                    )
                
                Text(title)
                    .font(.outfit(16, weight: .semiBold))
                    .foregroundStyle(textGradient)
            }
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private var buttonBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.40, green: 0.27, blue: 0.96),
                Color(red: 0.32, green: 0.21, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color.white.opacity(0.7)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ContinueButtonView(title: "Continue", isEnabled: true, action: {})
        ContinueButtonView(title: "Continue", isEnabled: false, action: {})
    }
    .padding()
    .background(Color.white)
}



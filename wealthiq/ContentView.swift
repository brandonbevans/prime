//
//  ContentView.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI
import SuperwallKit


struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("WealthIQ Rules")
            Button("Show Paywall") {
                Superwall.shared.register(placement: "campaign_trigger")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

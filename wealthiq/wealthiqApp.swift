//
//  wealthiqApp.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI
import SuperwallKit

@main
struct wealthiqApp: App {
    init() {
        Superwall.configure(apiKey: "pk_O6OOH8nnv59iWMHyQiCvg")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

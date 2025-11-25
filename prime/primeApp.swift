//
//  primeApp.swift
//  prime
//
//  Created by Brandon Bevans on 11/10/25.
//

import SwiftUI
import SuperwallKit
import FirebaseCore

@main
struct primeApp: App {
    init() {
        // Initialize Firebase first
        FirebaseApp.configure()
        
        Superwall.configure(apiKey: "pk_O6OOH8nnv59iWMHyQiCvg")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

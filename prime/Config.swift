//
//  Config.swift
//  prime
//
//  Created on 11/17/25.
//
//  IMPORTANT: Supabase configuration is loaded from Info.plist
//  Update the values in Info.plist with your actual Supabase credentials
//

import Foundation

/// Application configuration for Supabase
///
/// To set up:
/// 1. Open Info.plist in Xcode
/// 2. Update the following keys with your Supabase credentials:
///    - SUPABASE_URL: Your Supabase project URL (e.g., https://xyzcompany.supabase.co)
///    - SUPABASE_ANON_KEY: Your Supabase anon/public API key
/// 3. These should match the values in `/frontend/.env.local`:
///    - SUPABASE_URL = NEXT_PUBLIC_SUPABASE_URL
///    - SUPABASE_ANON_KEY = NEXT_PUBLIC_SUPABASE_ANON_KEY
/// 4. If not available, get them from your Supabase project dashboard:
///    - Navigate to Settings > API
///    - Copy your Project URL and anon/public API key
///
/// Security Note: The anon key is safe to use in client applications
/// as it's designed for public access with Row Level Security (RLS)
struct Config {
  /// Your Supabase project URL
  /// Loaded from Info.plist SUPABASE_URL key
  /// Same as NEXT_PUBLIC_SUPABASE_URL in frontend/.env.local
  static var supabaseURL: String {
    let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL")
    
    guard let url = rawValue as? String else {
      fatalError("SUPABASE_URL not found in Info.plist. Please add your Supabase project URL.")
    }
    
    return url
  }

  /// Your Supabase anon/public API key
  /// Loaded from Info.plist SUPABASE_ANON_KEY key
  /// Same as NEXT_PUBLIC_SUPABASE_ANON_KEY in frontend/.env.local
  static var supabaseAnonKey: String {
    let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY")
    
    guard let key = rawValue as? String else {
      fatalError("SUPABASE_ANON_KEY not found in Info.plist. Please add your Supabase anon key.")
    }
    
    return key
  }

  /// Validate that the configuration has been set
  static var isConfigured: Bool {
    let urlRaw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL")
    let keyRaw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY")
    
    // Try to load both values and check they're not empty
    if let url = urlRaw as? String,
      let key = keyRaw as? String
    {
      return !url.isEmpty && !key.isEmpty
    }
    
    return false
  }
}

/// Helper to load configuration from environment or plist if needed
/// This can be enhanced to load from Info.plist or environment variables
extension Config {
  static func loadFromEnvironment() {
    // Optional: Load from Info.plist
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
      NSDictionary(contentsOfFile: path) != nil
    {
      // Load values from plist if available
      // This allows keeping sensitive data out of source control
    }

    // Optional: Load from environment variables during development
    // ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? supabaseURL
  }
}

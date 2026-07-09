//
//  AppConfig.swift
//  Loopline
//
//  Centralises external configuration (API keys, URLs).
//  Reads from Secrets.swift (gitignored) which holds the actual values.
//

import Foundation

/// App-wide configuration constants accessible from any isolation domain.
enum AppConfig {
    // These are compile-time constants, safe to access from any actor.
    nonisolated static let supabaseURL: URL = URL(string: Secrets.supabaseURLString)!
    nonisolated static let supabaseAnonKey: String = Secrets.supabaseAnonKey
}

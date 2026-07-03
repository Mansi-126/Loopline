//
//  SupabaseService.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation
import Supabase

/// All backend I/O. Anonymous auth keeps onboarding frictionless;
/// the profile row carries the display name + emoji.
actor SupabaseService {
    static let shared = SupabaseService()

    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://ohyrmnrhuxdasyfrhidm.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oeXJtbnJodXhkYXN5ZnJoaWRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwODc0OTUsImV4cCI6MjA5ODY2MzQ5NX0.fKY_g_sbGG6g0NoIM-IsIntiwfGq5d5O6xCSm6Knx9I"
    )

    func signInIfNeeded(profile: Profile) async -> Profile {
        var updated = profile
        do {
            if client.auth.currentSession == nil {
                let session = try await client.auth.signInAnonymously()
                updated.id = session.user.id
            } else if let user = client.auth.currentUser {
                updated.id = user.id
            }
        } catch {
            print("⚠️ Supabase auth failed (offline OK):", error)
        }
        return updated
    }

    func upsertProfile(_ profile: Profile) async {
        struct Row: Encodable {
            let id: UUID, display_name: String, emoji: String
        }
        try? await client.from("profiles")
            .upsert(Row(id: profile.id, display_name: profile.displayName, emoji: profile.emoji))
            .execute()
    }

    func submit(result: GameResult, profile: Profile) async {
        struct Row: Encodable {
            let user_id: UUID, level_id: String, kind: String
            let time_seconds: Double, backtracks: Int, hints_used: Int
        }
        try? await client.from("solves")
            .upsert(Row(user_id: profile.id, level_id: result.level.id,
                        kind: result.level.kind.rawValue,
                        time_seconds: result.time,
                        backtracks: result.backtracks,
                        hints_used: result.hintsUsed),
                    onConflict: "user_id,level_id")
            .execute()
    }

    func fetchDailyLeaderboard(levelId: String) async -> [LeaderboardEntry] {
        do {
            var entries: [LeaderboardEntry] = try await client
                .from("daily_leaderboard")
                .select()
                .eq("level_id", value: levelId)
                .order("time_seconds", ascending: true)
                .order("backtracks", ascending: true)
                .order("hints_used", ascending: true)
                .limit(100)
                .execute()
                .value
            for i in entries.indices { entries[i].rank = i + 1 }
            return entries
        } catch {
            print("⚠️ Leaderboard fetch failed:", error)
            return []
        }
    }
}

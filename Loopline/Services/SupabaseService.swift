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
                print("✅ Signed in anonymously. User ID: \(session.user.id)")
            } else if let user = client.auth.currentUser {
                updated.id = user.id
                print("✅ Already signed in. User ID: \(user.id)")
            }
        } catch {
            print("❌ Supabase auth FAILED:", error)
        }
        return updated
    }

    func upsertProfile(_ profile: Profile) async {
        struct Row: Encodable {
            let id: UUID, display_name: String, emoji: String
        }
        do {
            try await client.from("profiles")
                .upsert(Row(id: profile.id, display_name: profile.displayName, emoji: profile.emoji))
                .execute()
            print("✅ Profile saved to DB: \(profile.displayName) (\(profile.id))")
        } catch {
            print("❌ Profile upsert FAILED:", error)
        }
    }

    @discardableResult
    func submit(result: GameResult, profile: Profile) async -> Bool {
        struct Row: Encodable {
            let user_id: UUID, level_id: String, kind: String
            let time_seconds: Double, backtracks: Int, hints_used: Int
        }
        do {
            try await client.from("solves")
                .upsert(Row(user_id: profile.id, level_id: result.level.id,
                            kind: result.level.kind.rawValue,
                            time_seconds: result.time,
                            backtracks: result.backtracks,
                            hints_used: result.hintsUsed),
                        onConflict: "user_id,level_id")
                .execute()
            return true
        } catch {
            print("⚠️ Solve submit failed (offline OK):", error)
            return false
        }
    }

    func fetchDailyLeaderboard(levelId: String, todayOnly: Bool = true) async -> [LeaderboardEntry] {
        do {
            var query = client
                .from("daily_leaderboard")
                .select()
                .eq("level_id", value: levelId)

            if todayOnly {
                // Filter to today's solves (UTC day start)
                let todayStart = Calendar.current.startOfDay(for: Date())
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                let todayStr = formatter.string(from: todayStart)
                query = query.gte("created_at", value: todayStr)
            }

            let entries: [LeaderboardEntry] = try await query
                .order("rank", ascending: true)
                .limit(100)
                .execute()
                .value

            return entries
        } catch {
            print("❌ Leaderboard fetch failed:", error)
            return []
        }
    }

    /// Fetches the current user's rank for a specific daily level.
    func fetchMyRank(userId: UUID, levelId: String) async -> (rank: Int, totalPlayers: Int)? {
        do {
            let entries: [LeaderboardEntry] = try await client
                .from("daily_leaderboard")
                .select()
                .eq("level_id", value: levelId)
                .order("rank", ascending: true)
                .execute()
                .value

            let totalPlayers = entries.count
            if let myEntry = entries.first(where: { $0.id == userId }) {
                return (rank: myEntry.rank, totalPlayers: totalPlayers)
            }
            return nil
        } catch {
            print("❌ Rank fetch failed:", error)
            return nil
        }
    }
}

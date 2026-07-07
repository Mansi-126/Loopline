//
//  Profile.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

struct Profile: Codable {
    var id: UUID
    var displayName: String
    var emoji: String

    static func anonymous() -> Profile {
        Profile(id: UUID(), displayName: "", emoji: ["🦊","🐙","🦉","🐢","🦋","🐝"].randomElement()!)
    }
}

struct StreakState: Codable {
    var count: Int = 0
    var lastSolveDay: String? = nil   // "yyyy-MM-dd" UTC
    var solvedToday: Bool = false
}

struct LeaderboardEntry: Identifiable, Decodable {
    let id: UUID
    let displayName: String
    let emoji: String
    let timeSeconds: Double
    let backtracks: Int
    let hintsUsed: Int
    let rank: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "user_id", displayName = "display_name", emoji,
             timeSeconds = "time_seconds", backtracks, hintsUsed = "hints_used",
             rank, createdAt = "created_at"
    }
}

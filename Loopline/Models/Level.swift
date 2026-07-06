//
//  Level.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

struct Level: Identifiable, Equatable, Codable {
    enum Kind: String, Codable { case campaign, daily }

    /// Difficulty tier for a campaign level. Every tier recurs throughout the
    /// campaign so players always get a mix of easy, moderate and hard puzzles.
    enum Difficulty: String, Codable, CaseIterable {
        case easy, moderate, hard

        var label: String {
            switch self {
            case .easy:     return "Easy"
            case .moderate: return "Moderate"
            case .hard:     return "Hard"
            }
        }
    }

    /// Total number of campaign levels.
    static let campaignCount = 200

    let id: String
    let kind: Kind
    let index: Int          // campaign: 1...N ; daily: day number
    let size: Int           // grid size
    let waypointCount: Int
    let seed: UInt64

    /// The difficulty tier of this level (campaign only; daily is treated as moderate).
    var difficulty: Difficulty {
        guard kind == .campaign else { return .moderate }
        return Level.campaignDifficulty(for: index)
    }

    /// Rotates easy → moderate → hard so all three tiers appear across the whole
    /// campaign, while the base grid still grows for overall progression.
    static func campaignDifficulty(for i: Int) -> Difficulty {
        switch (i - 1) % 3 {
        case 0:  return .easy
        case 1:  return .moderate
        default: return .hard
        }
    }

    static func campaign(_ i: Int) -> Level {
        // Base grid grows gradually across the 200-level campaign (4×4 → 7×7).
        let difficulty = campaignDifficulty(for: i)
        let baseSize = min(7, 4 + (i - 1) / 50)

        let size: Int
        let waypoints: Int
        switch difficulty {
        case .easy:
            size = baseSize
            waypoints = max(3, size - 1)
        case .moderate:
            size = min(8, baseSize + 1)
            waypoints = size + 1
        case .hard:
            size = min(9, baseSize + 2)
            waypoints = size + 3
        }

        return Level(id: "c\(i)", kind: .campaign, index: i,
                     size: size, waypointCount: waypoints,
                     seed: 0xC0FFEE &+ UInt64(i) &* 7919)
    }

    static func daily(for date: Date = .now) -> Level {
        let seed = SeededRNG.dailySeed(for: date)
        return Level(id: "d\(seed)", kind: .daily,
                     index: Int(seed % 1000),
                     size: 6, waypointCount: 8, seed: seed)
    }
}

struct Progress: Codable {
    var completedLevels: Set<String> = []
    var bestTimes: [String: TimeInterval] = [:]
    var totalSolved: Int = 0

    var highestUnlocked: Int {
        var i = 1
        while completedLevels.contains("c\(i)") { i += 1 }
        return i
    }

    mutating func record(result: GameResult) {
        completedLevels.insert(result.level.id)
        totalSolved += 1
        let prev = bestTimes[result.level.id] ?? .infinity
        bestTimes[result.level.id] = min(prev, result.time)
    }
}

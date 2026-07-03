//
//  Level.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

struct Level: Identifiable, Equatable, Codable {
    enum Kind: String, Codable { case campaign, daily }

    let id: String
    let kind: Kind
    let index: Int          // campaign: 1...N ; daily: day number
    let size: Int           // grid size
    let waypointCount: Int
    let seed: UInt64

    static func campaign(_ i: Int) -> Level {
        // Difficulty curve: 4×4 → 8×8, more waypoints as grids grow.
        let size = min(8, 4 + (i - 1) / 5)
        let waypoints = min(size + 2, 4 + (i - 1) / 3)
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

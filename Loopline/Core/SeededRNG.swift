//
//  SeededRNG.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

/// SplitMix64 — deterministic RNG so the daily puzzle is identical for
/// every player worldwide (seeded by the UTC date).
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    static func dailySeed(for date: Date = .now) -> UInt64 {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return UInt64(c.year! * 10_000 + c.month! * 100 + c.day!) &* 0x2545F4914F6CDD1D
    }
}

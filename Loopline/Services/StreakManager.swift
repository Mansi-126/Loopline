//
//  StreakManager.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

/// Streak rules (UTC-based, same clock as puzzle rollover):
/// · Solve today's daily → +1
/// · Miss a full day → streak resets to 0
enum StreakManager {
    private static var utcDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static func todayKey(_ date: Date = .now) -> String { utcDayFormatter.string(from: date) }
    static func yesterdayKey(_ date: Date = .now) -> String {
        utcDayFormatter.string(from: date.addingTimeInterval(-86_400))
    }

    /// Run on launch: expire stale streaks, refresh `solvedToday`.
    static func evaluate(_ state: StreakState) -> StreakState {
        var s = state
        guard let last = s.lastSolveDay else { return s }
        if last == todayKey() { s.solvedToday = true }
        else if last == yesterdayKey() { s.solvedToday = false }
        else { s = StreakState() }   // missed a day — reset
        return s
    }

    static func recordDailySolve(_ state: StreakState) -> StreakState {
        var s = state
        guard s.lastSolveDay != todayKey() else { return s }
        s.count = (s.lastSolveDay == yesterdayKey()) ? s.count + 1 : 1
        s.lastSolveDay = todayKey()
        s.solvedToday = true
        return s
    }
}

//
//  ProgressStore.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

/// Local persistence — instant, offline-first. Supabase is the sync layer,
/// UserDefaults+JSON is the source of truth on device.
struct ProgressStore {
    private let defaults = UserDefaults.standard

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: "onboarded") }
        nonmutating set { defaults.set(newValue, forKey: "onboarded") }
    }

    func save<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    func save(profile: Profile)   { save(profile, key: "profile") }
    func save(progress: Progress) { save(progress, key: "progress") }
    func save(streak: StreakState){ save(streak, key: "streak") }

    func loadProfile() -> Profile?  { load(Profile.self, key: "profile") }
    func loadProgress() -> Progress { load(Progress.self, key: "progress") ?? Progress() }
    func loadStreak() -> StreakState{ load(StreakState.self, key: "streak") ?? StreakState() }

    // MARK: - Pending Solves (offline queue)

    func addPendingSolve(_ result: GameResult) {
        var pending = loadPendingSolves()
        // Replace if same level already pending
        pending.removeAll { $0.level.id == result.level.id }
        pending.append(result)
        save(pending, key: "pendingSolves")
    }

    func removePendingSolve(levelId: String) {
        var pending = loadPendingSolves()
        pending.removeAll { $0.level.id == levelId }
        save(pending, key: "pendingSolves")
    }

    func loadPendingSolves() -> [GameResult] {
        load([GameResult].self, key: "pendingSolves") ?? []
    }
}

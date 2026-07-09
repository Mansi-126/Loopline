//
//  LooplineApp.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//
//
//import SwiftUI
//
//@main
//struct LooplineApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


import SwiftUI
import Combine

@main
struct LooplineApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

/// Global app state — single source of truth for navigation + player data.
@MainActor
final class AppState: ObservableObject {
    @Published var route: Route = .launch
    @Published var profile: Profile
    @Published var progress: Progress
    @Published var streak: StreakState

    let supabase = SupabaseService.shared
    private let store = ProgressStore()

    enum Route: Equatable {
        case launch
        case onboarding
        case map
        case game(Level)
        case result(GameResult)
    }

    init() {
        profile = store.loadProfile() ?? Profile.anonymous()
        progress = store.loadProgress()
        streak = StreakManager.evaluate(store.loadStreak())
    }

    func boot() async {
        // Move on as soon as the zip line finishes drawing 1 → 2 → 3
        // (1.5x-speed draw fills by ~1.25s), then open the home screen.
        try? await Task.sleep(for: .seconds(1.3)) // launch animation beat
        withAnimation(.snappy(duration: 0.5)) {
            route = store.hasOnboarded ? .map : .onboarding
        }
        // Auth with Supabase
        profile = await supabase.signInIfNeeded(profile: profile)
        store.save(profile: profile)

        // Always upsert profile to Supabase after auth so it's in the DB
        await supabase.upsertProfile(profile)

        // Sync any pending solves that may have failed previously
        await syncPendingSolves()
    }

    func completeOnboarding(name: String) {
        profile.displayName = name
        store.hasOnboarded = true
        store.save(profile: profile)
        Task { await supabase.upsertProfile(profile) }
        withAnimation(.snappy) { route = .map }
    }

    func updateName(_ name: String) {
        profile.displayName = name
        store.save(profile: profile)
        Task { await supabase.upsertProfile(profile) }
    }

    func updateEmoji(_ emoji: String) {
        profile.emoji = emoji
        store.save(profile: profile)
        Task { await supabase.upsertProfile(profile) }
    }

    func resetProgress() {
        progress = Progress()
        streak = StreakState()
        store.save(progress: progress)
        store.save(streak: streak)
    }

    func syncToCloud() async {
        await supabase.upsertProfile(profile)
        await syncPendingSolves()
    }

    func finish(result: GameResult) {
        progress.record(result: result)
        if result.level.kind == .daily {
            streak = StreakManager.recordDailySolve(streak)
            store.save(streak: streak)
        }
        store.save(progress: progress)
        // Save locally as pending, then try to submit
        store.addPendingSolve(result)
        Task {
            let success = await supabase.submit(result: result, profile: profile)
            if success {
                store.removePendingSolve(levelId: result.level.id)
            }
        }
        withAnimation(.snappy) { route = .result(result) }
    }

    /// Retry uploading any solves that failed previously (e.g. was offline)
    private func syncPendingSolves() async {
        let pending = store.loadPendingSolves()
        for solve in pending {
            let success = await supabase.submit(result: solve, profile: profile)
            if success {
                store.removePendingSolve(levelId: solve.level.id)
            }
        }
    }
}

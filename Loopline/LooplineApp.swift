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
        profile = ProgressStore().loadProfile() ?? Profile.anonymous()
        progress = ProgressStore().loadProgress()
        streak = StreakManager.evaluate(ProgressStore().loadStreak())
    }

    func boot() async {
        try? await Task.sleep(for: .seconds(1.2)) // launch animation beat
        withAnimation(.snappy(duration: 0.5)) {
            route = store.hasOnboarded ? .map : .onboarding
        }
       profile = await supabase.signInIfNeeded(profile: profile)
    }

    func completeOnboarding(name: String) {
        profile.displayName = name
        store.hasOnboarded = true
        store.save(profile: profile)
        Task { await supabase.upsertProfile(profile) }
        withAnimation(.snappy) { route = .map }
    }

    func finish(result: GameResult) {
        progress.record(result: result)
        if result.level.kind == .daily {
            streak = StreakManager.recordDailySolve(streak)
            store.save(streak: streak)
        }
        store.save(progress: progress)
        Task { await supabase.submit(result: result, profile: profile) }
        withAnimation(.snappy) { route = .result(result) }
    }
}

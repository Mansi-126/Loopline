//
//  ResultView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var app: AppState
    let result: GameResult
    @State private var revealed = 0
    @State private var showLeaderboard = false

    var body: some View {
        ZStack {
            VStack(spacing: 28) {
                Spacer()
                Text("Solved!")
                    .font(Theme.font(.display)).foregroundStyle(Theme.ink)
                    .scaleEffect(revealed >= 1 ? 1 : 0.5)
                    .opacity(revealed >= 1 ? 1 : 0)

                if result.level.kind == .daily {
                    streakBadge.opacity(revealed >= 2 ? 1 : 0)
                        .scaleEffect(revealed >= 2 ? 1 : 0.8)
                }

                // LinkedIn-style stat trio: time / backtracks / hints
                HStack(spacing: 14) {
                    StatTile(icon: "stopwatch.fill", value: result.time.clockString,
                             label: "Time", show: revealed >= 3)
                    StatTile(icon: "arrow.uturn.backward", value: "\(result.backtracks)",
                             label: "Backtracks", show: revealed >= 4)
                    StatTile(icon: "lightbulb.fill", value: "\(result.hintsUsed)",
                             label: "Hints", show: revealed >= 5)
                }
                .padding(.horizontal, 24)

                Spacer()

                if result.level.kind == .daily {
                    Button {
                        showLeaderboard = true
                    } label: {
                        Label("See Leaderboard", systemImage: "trophy.fill")
                            .font(Theme.font(.headline)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 24)
                    .opacity(revealed >= 6 ? 1 : 0)
                }

                Button {
                    withAnimation(.snappy) { app.route = .map }
                } label: {
                    Text("Continue")
                        .font(Theme.font(.headline)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 24).padding(.bottom, 24)
                .opacity(revealed >= 6 ? 1 : 0)
            }

            ConfettiView().allowsHitTesting(false)
        }
        .background(Theme.background)
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(myResult: result)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .onAppear { revealSequence() }
    }

    private var streakBadge: some View {
        HStack(spacing: 8) {
            StreakFlameView(active: true).frame(width: 32, height: 32)
            Text("\(app.streak.count) day streak")
                .font(Theme.font(.headline)).foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Theme.accentSoft, in: Capsule())
    }

    private func revealSequence() {
        for step in 1...6 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)
                .delay(Double(step) * 0.18)) { revealed = step }
        }
    }
}

private struct StatTile: View {
    let icon: String, value: String, label: String, show: Bool
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Theme.accent)
            Text(value).font(Theme.font(.mono)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.font(.caption)).foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        .cardShadow()
        .opacity(show ? 1 : 0)
        .scaleEffect(show ? 1 : 0.85)
    }
}

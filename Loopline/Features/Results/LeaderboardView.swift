//
//  LeaderboardView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var app: AppState
    let myResult: GameResult
    @State private var entries: [LeaderboardEntry] = []
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            Text("Today's Leaderboard")
                .font(Theme.font(.title)).foregroundStyle(Theme.ink)
                .padding(.top, 28).padding(.bottom, 4)
            Text("Ranked by time · backtracks · hints")
                .font(Theme.font(.caption)).foregroundStyle(Theme.inkSecondary)
                .padding(.bottom, 16)

            if loading {
                Spacer(); ProgressView().tint(Theme.accent); Spacer()
            } else if entries.isEmpty {
                Spacer()
                Text("Be the first to solve today! 🏁")
                    .font(Theme.font(.body)).foregroundStyle(Theme.inkSecondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(entries) { entry in
                            LeaderboardRow(entry: entry, isMe: entry.id == app.profile.id)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Theme.background)
        .task {
            entries = await app.supabase.fetchDailyLeaderboard(levelId: myResult.level.id)
            withAnimation(.snappy) { loading = false }
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(rankLabel)
                .font(Theme.font(.headline))
                .foregroundStyle(entry.rank <= 3 ? Theme.gold : Theme.inkSecondary)
                .frame(width: 36)
            Text(entry.emoji).font(.system(size: 24))
            Text(entry.displayName + (isMe ? " (you)" : ""))
                .font(Theme.font(.body))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(TimeInterval(entry.timeSeconds).clockString)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                Text("↩︎ \(entry.backtracks) · 💡 \(entry.hintsUsed)")
                    .font(Theme.font(.caption)).foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(isMe ? Theme.accentSoft : Theme.surface,
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(isMe ? Theme.accent : .clear, lineWidth: 2))
        .cardShadow()
    }

    private var rankLabel: String {
        switch entry.rank { case 1: "🥇"; case 2: "🥈"; case 3: "🥉"; default: "#\(entry.rank)" }
    }
}

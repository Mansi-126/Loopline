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
    @State private var selectedFilter: LeaderboardFilter = .today
    @State private var rowsVisible = false

    enum LeaderboardFilter: String, CaseIterable {
        case today = "Today"
        case allTime = "All Time"
    }

    private var myEntry: LeaderboardEntry? {
        entries.first(where: { $0.id == app.profile.id })
    }

    private var isMyEntryInTop10: Bool {
        guard let entry = myEntry else { return false }
        return entry.rank <= 10
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Theme.boardLine)
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            // Header
            header
                .padding(.top, 20)
                .padding(.bottom, 8)

            // Filter toggle
            filterToggle
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            if loading {
                Spacer()
                loadingView
                Spacer()
            } else if entries.isEmpty {
                Spacer()
                emptyView
                Spacer()
            } else {
                // Podium for top 3
                if entries.count >= 3 {
                    podiumView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                // Scrollable list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(entries.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRow(entry: entry, isMe: entry.id == app.profile.id)
                                .opacity(rowsVisible ? 1 : 0)
                                .offset(y: rowsVisible ? 0 : 12)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                    value: rowsVisible
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
            }

            // Pinned player row (if not in visible top)
            if !loading && !isMyEntryInTop10 && myEntry == nil {
                pinnedPlayerRow
            }
        }
        .background(Theme.background)
        .task {
            entries = await app.supabase.fetchDailyLeaderboard(levelId: myResult.level.id)
            withAnimation(.snappy) { loading = false }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) { rowsVisible = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.gold)
                Text("Leaderboard")
                    .font(Theme.font(.title))
                    .foregroundStyle(Theme.ink)
            }

            if myResult.level.kind == .daily {
                Text("Daily Challenge")
                    .font(Theme.font(.caption))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.accent, in: Capsule())
            }

            Text("Ranked by time · backtracks · hints")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 2)
        }
    }

    // MARK: - Filter Toggle

    private var filterToggle: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(Theme.font(.caption))
                        .foregroundStyle(selectedFilter == filter ? .white : Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                            ? AnyShapeStyle(Theme.accent)
                            : AnyShapeStyle(.clear),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.boardLine, lineWidth: 1))
        .cardShadow()
    }

    // MARK: - Podium View (Top 3)

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if entries.count > 1 {
                podiumCard(entry: entries[1], height: 100)
            }
            if entries.count > 0 {
                podiumCard(entry: entries[0], height: 130)
            }
            if entries.count > 2 {
                podiumCard(entry: entries[2], height: 85)
            }
        }
    }

    private func podiumCard(entry: LeaderboardEntry, height: CGFloat) -> some View {
        let isMe = entry.id == app.profile.id
        return VStack(spacing: 8) {
            // Medal
            Text(medalEmoji(for: entry.rank))
                .font(.system(size: entry.rank == 1 ? 32 : 24))

            // Avatar
            ZStack {
                Circle()
                    .fill(isMe ? Theme.accentSoft : Theme.surface)
                    .frame(width: entry.rank == 1 ? 56 : 44, height: entry.rank == 1 ? 56 : 44)
                    .overlay(
                        Circle()
                            .stroke(
                                entry.rank == 1 ? Theme.gold : Theme.boardLine,
                                lineWidth: entry.rank == 1 ? 3 : 2
                            )
                    )
                    .cardShadow()
                Text(entry.emoji)
                    .font(.system(size: entry.rank == 1 ? 28 : 22))
            }

            // Name
            Text(entry.displayName + (isMe ? " (you)" : ""))
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            // Time
            Text(TimeInterval(entry.timeSeconds).clockString)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: height)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isMe ? Theme.accentSoft : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            entry.rank == 1
                            ? LinearGradient(colors: [Theme.gold, Theme.gold.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Theme.boardLine, Theme.boardLine], startPoint: .top, endPoint: .bottom),
                            lineWidth: entry.rank == 1 ? 2 : 1
                        )
                )
        )
        .cardShadow()
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.2)
            Text("Loading rankings...")
                .font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkSecondary)
            Text("Be the first to solve today!")
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.ink)
            Text("Your time will appear here once submitted.")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    // MARK: - Pinned Player Row

    private var pinnedPlayerRow: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.boardLine)
            HStack(spacing: 14) {
                Text("You")
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text(app.profile.emoji)
                    .font(.system(size: 20))
                Text(app.profile.displayName)
                    .font(Theme.font(.body))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(myResult.time.clockString)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.accentSoft)
        }
    }

    private func medalEmoji(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text(rankLabel)
                .font(Theme.font(.headline))
                .foregroundStyle(entry.rank <= 3 ? Theme.gold : Theme.inkSecondary)
                .frame(width: 36)

            // Avatar
            ZStack {
                Circle()
                    .fill(isMe ? Theme.accentSoft : Theme.boardLine.opacity(0.5))
                    .frame(width: 38, height: 38)
                Text(entry.emoji)
                    .font(.system(size: 20))
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName + (isMe ? " (you)" : ""))
                    .font(Theme.font(.body))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if entry.backtracks > 0 {
                        Label("\(entry.backtracks)", systemImage: "arrow.uturn.backward")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    if entry.hintsUsed > 0 {
                        Label("\(entry.hintsUsed)", systemImage: "lightbulb.fill")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }

            Spacer()

            // Time
            Text(TimeInterval(entry.timeSeconds).clockString)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isMe ? Theme.accentSoft : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMe ? Theme.accent.opacity(0.5) : .clear, lineWidth: 2)
        )
        .cardShadow()
    }

    private var rankLabel: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }
}

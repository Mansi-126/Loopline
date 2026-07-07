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
    @State private var rankGlow: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var myRankInfo: (rank: Int, totalPlayers: Int)?
    @State private var rankLoading = true

    // Real rank from Supabase — falls back to nil if not yet loaded
    private var playerRank: Int? { myRankInfo?.rank }
    private var totalPlayers: Int { myRankInfo?.totalPlayers ?? 0 }
    private var percentile: Int {
        guard let info = myRankInfo, info.totalPlayers > 1 else { return 0 }
        return max(1, Int(Double(info.totalPlayers - info.rank) / Double(info.totalPlayers) * 100))
    }

    var body: some View {
        ZStack {
            // Background with subtle radial gradient
            Theme.background.ignoresSafeArea()
            RadialGradient(
                colors: [Theme.accentSoft.opacity(0.3), Theme.background],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // MARK: - Solved Header
                    solvedHeader
                        .opacity(revealed >= 1 ? 1 : 0)
                        .scaleEffect(revealed >= 1 ? 1 : 0.6)
                        .offset(y: revealed >= 1 ? 0 : 20)

                    // MARK: - Rank Display (Daily only)
                    if result.level.kind == .daily {
                        rankSection
                            .opacity(revealed >= 2 ? 1 : 0)
                            .scaleEffect(revealed >= 2 ? 1 : 0.85)
                            .offset(y: revealed >= 2 ? 0 : 15)
                    }

                    // MARK: - Streak Badge (Daily only)
                    if result.level.kind == .daily {
                        streakBadge
                            .opacity(revealed >= 3 ? 1 : 0)
                            .scaleEffect(revealed >= 3 ? 1 : 0.8)
                    }

                    // MARK: - Stats Row
                    statsRow
                        .padding(.horizontal, 20)

                    Spacer(minLength: 20)

                    // MARK: - Action Buttons
                    actionButtons
                        .opacity(revealed >= 6 ? 1 : 0)
                        .offset(y: revealed >= 6 ? 0 : 20)
                }
                .padding(.bottom, 40)
            }

            // Confetti overlay
            ConfettiView()
                .allowsHitTesting(false)
                .opacity(revealed >= 1 ? 1 : 0)

            // Close button — returns to the home level map
            closeButton
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(result: result)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .task {
            // Fetch real rank from Supabase after the solve has been submitted
            if result.level.kind == .daily {
                myRankInfo = await app.supabase.fetchMyRank(userId: app.profile.id, levelId: result.level.id)
            }
            rankLoading = false
        }
        .onAppear { revealSequence() }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.shared.waypoint()
                    withAnimation(.snappy) { app.route = .map }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(width: 40, height: 40)
                        .background(
                            ZStack {
                                Circle().fill(Color(hex: 0xE8E4DD)).offset(y: 3)
                                Circle().fill(Theme.surface)
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .clear],
                                            startPoint: .top, endPoint: .center
                                        )
                                    )
                            }
                        )
                        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Close")
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Solved Header

    private var solvedHeader: some View {
        VStack(spacing: 8) {
            Text("🎉")
                .font(.system(size: 52))
            Text("Solved!")
                .font(Theme.font(.display))
                .foregroundStyle(Theme.ink)
            if result.level.kind == .campaign {
                Text("Level \(result.level.index) Complete")
                    .font(Theme.font(.body))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    // MARK: - Rank Section

    private var rankSection: some View {
        VStack(spacing: 10) {
            if rankLoading {
                ProgressView()
                    .tint(Theme.gold)
                    .scaleEffect(1.1)
                    .padding(.vertical, 20)
            } else if let rank = playerRank {
                // Rank number with golden glow
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.gold.opacity(0.4 * rankGlow), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    VStack(spacing: 2) {
                        Text("#\(rank)")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.gold, Theme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(shimmerOverlay(rank: rank))
                        Text("of \(totalPlayers) players today")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }

                // Percentile line
                if percentile > 0 {
                    Text("Faster than **\(percentile)%** of players")
                        .font(Theme.font(.body))
                        .foregroundStyle(Theme.ink)
                }

                // Score pill
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.gold)
                    Text("\(result.score) pts")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.gold.opacity(0.1), in: Capsule())
            } else {
                // No rank yet (submission may have failed)
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.gold)
                        Text("\(result.score) pts")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Theme.gold.opacity(0.1), in: Capsule())
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rankGlow = 1
            }
        }
    }

    // Shimmer overlay on rank
    private func shimmerOverlay(rank: Int) -> some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.4), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 60)
            .offset(x: shimmerOffset)
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = geo.size.width + 60
                }
            }
        }
        .mask(
            Text("#\(rank)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
        )
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        HStack(spacing: 10) {
            StreakFlameView(active: true)
                .frame(width: 28, height: 28)
            Text("\(app.streak.count) day streak")
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Theme.accentSoft)
                .overlay(
                    Capsule()
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
        .cardShadow()
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(
                icon: "stopwatch.fill",
                value: result.time.clockString,
                label: "Time",
                color: Theme.accent,
                show: revealed >= 3
            )
            StatTile(
                icon: "arrow.uturn.backward",
                value: "\(result.backtracks)",
                label: "Backtracks",
                color: Theme.gold,
                show: revealed >= 4
            )
            StatTile(
                icon: "lightbulb.fill",
                value: "\(result.hintsUsed)",
                label: "Hints",
                color: Color(hex: 0x5B8DEF),
                show: revealed >= 5
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if result.level.kind == .daily {
                Button {
                    showLeaderboard = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("See Leaderboard")
                            .font(Theme.font(.headline))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: 0xC9932E))
                                .offset(y: 4)
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.gold, Theme.gold.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear, .clear],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                        }
                    )
                    .shadow(color: Theme.gold.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
            }

            // Next Puzzle / Continue button (3D primary)
            Button {
                withAnimation(.snappy) { app.route = .map }
            } label: {
                Text("Next Puzzle →")
                    .font(Theme.font(.headline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: 0xD94E30))
                                .offset(y: 4)
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFF8566), Theme.accent, Theme.accent.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear, .clear],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                        }
                    )
                    .shadow(color: Theme.accent.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func revealSequence() {
        for step in 1...6 {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(step) * 0.22)
            ) {
                revealed = step
            }
        }
    }
}

// MARK: - Stat Tile Component

private struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let show: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Icon with colored background circle + 3D depth
            ZStack {
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: 42, height: 42)
                    .offset(y: 2)
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    center: .init(x: 0.35, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                    )
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(Theme.font(.mono))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())

            Text(label)
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            ZStack {
                // 3D bottom depth
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0xE8E4DD))
                    .offset(y: 4)

                // Main surface with glass feel
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.surface.opacity(0.7))
                    )

                // Top highlight for 3D bevel
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.boardLine.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 6)
        .opacity(show ? 1 : 0)
        .scaleEffect(show ? 1 : 0.8)
        .rotation3DEffect(
            .degrees(show ? 0 : -10),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .offset(y: show ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: show)
    }
}

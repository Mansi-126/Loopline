//
//  DailyCardView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI
import Combine

struct DailyCardView: View {
    @EnvironmentObject private var app: AppState
    @State private var now = Date()
    @State private var appeared = false
    @State private var playPulse = false
    @State private var showLeaderboard = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            guard !app.streak.solvedToday else { return }
            Haptics.shared.waypoint()
            withAnimation(.snappy) { app.route = .game(.daily()) }
        } label: {
            VStack(spacing: 10) {
                // Main card content
                HStack(spacing: 14) {
                    // Calendar date icon
                    calendarIcon

                    // Title + subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(app.streak.solvedToday ? "Completed!" : "Today's Challenge")
                                .font(Theme.font(.headline))
                                .foregroundStyle(Theme.ink)
                        }
                        
                        if app.streak.solvedToday {
                            Text("Next puzzle in \(countdown)")
                                .font(Theme.font(.caption))
                                .foregroundStyle(Theme.inkSecondary)
                                .contentTransition(.numericText())
                        } else if app.streak.count > 0 {
                            HStack(spacing: 4) {
                                StreakFlameView(active: true)
                                    .frame(width: 14, height: 14)
                                Text("\(app.streak.count) day streak")
                                    .font(Theme.font(.caption))
                                    .foregroundStyle(Theme.accent)
                            }
                        } else {
                            Text("Start your streak!")
                                .font(Theme.font(.caption))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }

                    Spacer()

                    // Status icon / Leaderboard button
                    if app.streak.solvedToday {
                        Button {
                            showLeaderboard = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.gold)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Theme.gold.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        statusIcon
                    }
                }

                // Weekly streak strip
                WeeklyStreakView()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // 3D bottom layer (depth shadow)
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(Color(hex: 0xE8E4DD))
                        .offset(y: 5)

                    // Main surface
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(Theme.surface)

                    // Top highlight for 3D bevel
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(
                        app.streak.solvedToday
                        ? LinearGradient(colors: [Theme.success, Theme.success.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 8)
            .shadow(color: .black.opacity(0.04), radius: 20, y: 14)
            // Subtle top gradient overlay for depth
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Theme.surface.opacity(0.8), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .allowsHitTesting(false)
            }
            // DAILY ribbon badge
            .overlay(alignment: .topTrailing) {
                Text("DAILY")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent, in: Capsule())
                    .offset(x: -12, y: -8)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(levelId: Level.daily().id, levelKind: .daily)
                .environmentObject(app)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .onReceive(timer) { now = $0 }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                playPulse = true
            }
        }
    }

    // MARK: - Calendar Icon

    private var calendarIcon: some View {
        VStack(spacing: 2) {
            Text(monthString)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
            Text(dayString)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
        .frame(width: 44, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.accentSoft.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        Group {
            if app.streak.solvedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.success)
                    .symbolEffect(.bounce, value: appeared)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(playPulse ? 1.08 : 1.0)
                    .shadow(color: Theme.accent.opacity(playPulse ? 0.4 : 0), radius: 8)
            }
        }
    }

    // MARK: - Helpers

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: now)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: now).uppercased()
    }

    private var countdown: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let midnight = cal.startOfDay(for: now.addingTimeInterval(86_400))
        let s = max(0, Int(midnight.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

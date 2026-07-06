//
//  WeeklyStreakView.swift
//  Loopline
//
//  Created by Mansi Gangani on 04/07/26.
//

import SwiftUI

/// 7-day horizontal strip showing this week's daily challenge completions.
/// Filled dots = completed, accent ring = today, dimmed = future.
struct WeeklyStreakView: View {
    @EnvironmentObject private var app: AppState
    @State private var dotsVisible = false

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                let state = dayState(for: index)
                VStack(spacing: 4) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(fillColor(for: state))
                            .frame(width: 28, height: 28)

                        // Today ring
                        if state == .today || state == .todayCompleted {
                            Circle()
                                .stroke(Theme.accent, lineWidth: 2.5)
                                .frame(width: 28, height: 28)
                        }

                        // Checkmark for completed
                        if state == .completed || state == .todayCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                        }

                        // Dot for future
                        if state == .future {
                            Circle()
                                .fill(Theme.locked.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .scaleEffect(dotsVisible ? 1 : 0.5)
                    .opacity(dotsVisible ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(index) * 0.06),
                        value: dotsVisible
                    )

                    Text(weekdays[index])
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            state == .today || state == .todayCompleted
                            ? Theme.accent
                            : Theme.inkSecondary
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.background.opacity(0.6))
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                dotsVisible = true
            }
        }
    }

    // MARK: - Day State Logic

    private enum DayState {
        case completed, today, todayCompleted, future, past
    }

    private func dayState(for weekdayIndex: Int) -> DayState {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: .now)
        // Convert to Monday=0 format
        let todayIndex = (today + 5) % 7

        if weekdayIndex == todayIndex {
            return app.streak.solvedToday ? .todayCompleted : .today
        } else if weekdayIndex < todayIndex {
            // Past day - check if it was part of current streak
            let daysAgo = todayIndex - weekdayIndex
            return wasCompletedDaysAgo(daysAgo) ? .completed : .past
        } else {
            return .future
        }
    }

    private func wasCompletedDaysAgo(_ daysAgo: Int) -> Bool {
        // If streak count covers this many days back, it was completed
        let effectiveStreak = app.streak.solvedToday ? app.streak.count : app.streak.count
        return daysAgo <= effectiveStreak
    }

    private func fillColor(for state: DayState) -> Color {
        switch state {
        case .completed, .todayCompleted:
            return Theme.success
        case .today:
            return Theme.accentSoft.opacity(0.5)
        case .past:
            return Theme.boardLine.opacity(0.4)
        case .future:
            return Theme.boardLine.opacity(0.2)
        }
    }
}

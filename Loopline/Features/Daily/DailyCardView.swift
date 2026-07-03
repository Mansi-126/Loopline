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
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            guard !app.streak.solvedToday else { return }
            withAnimation(.snappy) { app.route = .game(.daily()) }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Theme.accentSoft)
                    LogoMark(progress: 1).frame(width: 34, height: 34)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.streak.solvedToday ? "Solved! Next puzzle in" : "Today's Zip")
                        .font(Theme.font(.headline)).foregroundStyle(Theme.ink)
                    Text(app.streak.solvedToday ? countdown : dateString)
                        .font(Theme.font(.caption)).foregroundStyle(Theme.inkSecondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                if app.streak.solvedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28)).foregroundStyle(Theme.success)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28)).foregroundStyle(Theme.accent)
                        .symbolEffect(.pulse)
                }
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .cardShadow()
        }
        .buttonStyle(PressableButtonStyle())
        .onReceive(timer) { now = $0 }
    }

    private var dateString: String {
        now.formatted(.dateTime.weekday(.wide).month().day())
    }

    /// Live HH:MM:SS countdown to next UTC midnight.
    private var countdown: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let midnight = cal.startOfDay(for: now.addingTimeInterval(86_400))
        let s = max(0, Int(midnight.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", s/3600, (s%3600)/60, s%60)
    }
}

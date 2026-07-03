//
//  LevelMapView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct LevelMapView: View {
    @EnvironmentObject private var app: AppState
    private let totalLevels = 40

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    DailyCardView()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Winding node path, bottom-up like a trail.
                    LazyVStack(spacing: 0) {
                        ForEach((1...totalLevels).reversed(), id: \.self) { i in
                            LevelNodeView(
                                level: Level.campaign(i),
                                state: nodeState(i),
                                bestTime: app.progress.bestTimes["c\(i)"],
                                xOffset: sin(Double(i) * 0.9) * 90
                            ) {
                                withAnimation(.snappy) { app.route = .game(.campaign(i)) }
                            }
                            .id(i)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .onAppear {
                proxy.scrollTo(app.progress.highestUnlocked, anchor: .center)
            }
        }
        .safeAreaInset(edge: .top) { header }
        .background(Theme.background)
    }

    private var header: some View {
        HStack {
            Text("Loopline").font(Theme.font(.title)).foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 6) {
                StreakFlameView(active: app.streak.solvedToday)
                    .frame(width: 26, height: 26)
                Text("\(app.streak.count)")
                    .font(Theme.font(.headline))
                    .foregroundStyle(app.streak.solvedToday ? Theme.accent : Theme.inkSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.surface, in: Capsule())
            .cardShadow()
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func nodeState(_ i: Int) -> LevelNodeView.NodeState {
        if app.progress.completedLevels.contains("c\(i)") { return .completed }
        if i == app.progress.highestUnlocked { return .current }
        return i < app.progress.highestUnlocked ? .completed : .locked
    }
}

//
//  LevelMapView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

// MARK: - Preference Key to collect node center positions

private struct NodeCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGPoint] = [:]
    static func reduce(value: inout [Int: CGPoint], nextValue: () -> [Int: CGPoint]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct LevelMapView: View {
    @EnvironmentObject private var app: AppState
    @State private var scrollOffset: CGFloat = 0
    @State private var avatarNodeIndex: Int? = nil
    @State private var showAvatar = false
    @State private var nodeCenters: [Int: CGPoint] = [:]
    @State private var lastSeenLevel: Int = 0
    @State private var showProfile = false
    private let totalLevels = Level.campaignCount

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 100)

                    // Level path (levels laid out bottom-to-top: level 1 at bottom)
                    levelPath
                        .padding(.bottom, 8)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                    showAvatar = true
                }
                let current = app.progress.highestUnlocked
                if lastSeenLevel == 0 {
                    // First open — jump to current level instantly (no animation)
                    lastSeenLevel = current
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(current, anchor: .center)
                    }
                } else {
                    lastSeenLevel = current
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(mapBackground)
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(app)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Pinned Top Bar (header + daily challenge)

    private var topBar: some View {
        VStack(spacing: 0) {
            header
            DailyCardView()
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Map Background

    private var mapBackground: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Theme.accentSoft.opacity(0.08),
                    Theme.background,
                    Theme.background,
                    Color(hex: 0xE8F5E9).opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Profile button
            Button {
                showProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xE8E4DD))
                        .frame(width: 38, height: 38)
                        .offset(y: 2)
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Theme.accent.opacity(0.4), lineWidth: 1.5)
                        )
                    Text(app.profile.emoji)
                        .font(.system(size: 18))
                }
                .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
            }
            .buttonStyle(PressableButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Loopline")
                    .font(Theme.font(.title))
                    .foregroundStyle(Theme.ink)
                Text("Level \(app.progress.highestUnlocked)")
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            // 3D Streak pill
            HStack(spacing: 6) {
                StreakFlameView(active: app.streak.solvedToday)
                    .frame(width: 22, height: 22)
                Text("\(app.streak.count)")
                    .font(Theme.font(.headline))
                    .foregroundStyle(app.streak.solvedToday ? Theme.accent : Theme.inkSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule().fill(Color(hex: 0xE8E4DD)).offset(y: 3)
                    Capsule().fill(Theme.surface)
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center))
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 3)

            // 3D Progress pill
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.gold)
                Text("\(app.progress.totalSolved)")
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule().fill(Color(hex: 0xE8E4DD)).offset(y: 3)
                    Capsule().fill(Theme.surface)
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center))
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Level Path

    private var levelPath: some View {
        ZStack(alignment: .top) {
            // Connecting line drawn from actual node positions (behind nodes)
            PathLineOverlay(
                nodeCenters: nodeCenters,
                totalLevels: totalLevels,
                highestUnlocked: app.progress.highestUnlocked
            )

            // Level nodes (reversed: highest at top, level 1 at bottom)
            VStack(spacing: 0) {
                ForEach((1...totalLevels).reversed(), id: \.self) { i in
                    let isMilestone = i % 5 == 0
                    let xOffset = sin(Double(i) * 0.85) * 85

                    ZStack {
                        // Decorative elements near milestones
                        if isMilestone {
                            decorativeElement(for: i)
                        }

                        // The node
                        LevelNodeView(
                            level: Level.campaign(i),
                            state: nodeState(i),
                            bestTime: app.progress.bestTimes["c\(i)"],
                            isMilestone: isMilestone,
                            xOffset: xOffset
                        ) {
                            Haptics.shared.waypoint()
                            withAnimation(.snappy) { app.route = .game(.campaign(i)) }
                        }
                        .id(i)
                        // Report actual visual center (accounting for xOffset)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: NodeCenterPreferenceKey.self,
                                        value: [i: CGPoint(
                                            x: geo.frame(in: .named("levelMap")).midX + xOffset,
                                            y: geo.frame(in: .named("levelMap")).midY
                                        )]
                                    )
                            }
                        )

                        // Player avatar on current level
                        if i == app.progress.highestUnlocked && showAvatar {
                            playerAvatar
                                .offset(x: xOffset, y: -48)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .coordinateSpace(name: "levelMap")
        .onPreferenceChange(NodeCenterPreferenceKey.self) { centers in
            nodeCenters = centers
        }
    }

    // MARK: - Player Avatar

    private var playerAvatar: some View {
        VStack(spacing: 4) {
            ZStack {
                // 3D ambient shadow
                Circle()
                    .fill(.black.opacity(0.1))
                    .frame(width: 42, height: 42)
                    .offset(y: 6)
                    .blur(radius: 4)

                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 28
                        )
                    )
                    .frame(width: 52, height: 52)

                // Avatar circle with 3D sphere look
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Theme.accent, lineWidth: 2.5)
                    )
                    .overlay(
                        // Specular highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    center: .init(x: 0.3, y: 0.25),
                                    startRadius: 0,
                                    endRadius: 15
                                )
                            )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 4)

                Text(app.profile.emoji)
                    .font(.system(size: 20))
            }

            // "YOU" label with 3D depth
            ZStack {
                Capsule()
                    .fill(Color(hex: 0xD94E30))
                    .frame(width: 30, height: 14)
                    .offset(y: 2)
                Text("YOU")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent, in: Capsule())
            }
        }
    }

    // MARK: - Decorative Elements

    @ViewBuilder
    private func decorativeElement(for level: Int) -> some View {
        let xPos = sin(Double(level) * 0.85) * 85
        HStack {
            if level % 10 == 0 {
                // Major milestone - star burst
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.gold.opacity(0.4))
                    .offset(x: xPos - 50, y: -10)
            }
            
            // Subtle dots decoration
            Circle()
                .fill(Theme.boardLine.opacity(0.3))
                .frame(width: 6, height: 6)
                .offset(x: xPos + 55, y: 8)

            Circle()
                .fill(Theme.boardLine.opacity(0.2))
                .frame(width: 4, height: 4)
                .offset(x: xPos - 60, y: -5)
        }
    }

    // MARK: - State

    private func nodeState(_ i: Int) -> LevelNodeView.NodeState {
        if app.progress.completedLevels.contains("c\(i)") { return .completed }
        if i == app.progress.highestUnlocked { return .current }
        return i < app.progress.highestUnlocked ? .completed : .locked
    }
}

#Preview("Level Map") {
    LevelMapView()
        .environmentObject(AppState())
}

// MARK: - Path Line Overlay (drawn from actual node positions)

/// Draws smooth connecting curves between nodes using their real measured positions.
private struct PathLineOverlay: View {
    let nodeCenters: [Int: CGPoint]
    let totalLevels: Int
    let highestUnlocked: Int

    var body: some View {
        Canvas { ctx, size in
            // Collect sorted points
            let sortedPoints: [(index: Int, point: CGPoint)] = (1...totalLevels).compactMap { i in
                guard let pt = nodeCenters[i] else { return nil }
                return (i, pt)
            }

            guard sortedPoints.count >= 2 else { return }

            // Build smooth curve through all points
            let allPath = smoothPath(through: sortedPoints.map(\.point))

            // Build smooth curve through completed points only
            let completedPoints = sortedPoints.filter { $0.index <= highestUnlocked }
            let completedPath = completedPoints.count >= 2
                ? smoothPath(through: completedPoints.map(\.point))
                : Path()

            // Draw full dashed path (background)
            ctx.stroke(
                allPath,
                with: .color(Theme.boardLine),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
            )

            // Draw completed solid path (foreground)
            if completedPoints.count >= 2 {
                ctx.stroke(
                    completedPath,
                    with: .color(Theme.accent.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    /// Creates a smooth cubic Bézier path passing through all given points.
    private func smoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midY = (prev.y + curr.y) / 2

            // Use cubic curve with control points at the vertical midpoint
            // This creates a smooth S-curve between nodes
            path.addCurve(
                to: curr,
                control1: CGPoint(x: prev.x, y: midY),
                control2: CGPoint(x: curr.x, y: midY)
            )
        }

        return path
    }
}

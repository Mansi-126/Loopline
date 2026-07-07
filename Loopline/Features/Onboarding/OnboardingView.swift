//
//  OnboardingView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var app: AppState
    @State private var page = 0
    @State private var name = ""
    @FocusState private var nameFocused: Bool
    @State private var pageAppeared = false
    @State private var emojiFloat = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Subtle sparkle background
            SparkleBackground()
                .opacity(0.6)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        icon: { LineDrawDemo() },
                        title: "One line.\nEvery cell.",
                        subtitle: "Draw a single path through every square, hitting the numbers in order.",
                        isActive: page == 0
                    )
                    .tag(0)

                    OnboardPage(
                        icon: {
                            StreakFlameView(active: true)
                                .frame(width: 80, height: 80)
                        },
                        title: "Come back daily.",
                        subtitle: "A new puzzle drops every 24 hours. Keep your streak alive.",
                        isActive: page == 1
                    )
                    .tag(1)

                    namePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.8), value: page)

                pageDots
                primaryButton
            }
        }
        .background(Theme.background)
    }

    // MARK: - Name Page

    private var namePage: some View {
        VStack(spacing: 28) {
            Spacer()

            // Floating emoji avatar
            Text(app.profile.emoji)
                .font(.system(size: 72))
                .offset(y: reduceMotion ? 0 : (emojiFloat ? -4 : 4))
                .shadow(color: Theme.accent.opacity(0.15), radius: 12, y: 8)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: emojiFloat
                )
                .onAppear { if !reduceMotion { emojiFloat = true } }

            Text("What should we call you?")
                .font(Theme.font(.title))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Premium text field
            VStack(spacing: 8) {
                TextField("Your name", text: $name)
                    .font(Theme.font(.headline))
                    .multilineTextAlignment(.center)
                    .focused($nameFocused)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        nameFocused ? Theme.accent : Theme.boardLine,
                                        lineWidth: nameFocused ? 2 : 1.5
                                    )
                            )
                    )
                    .cardShadow()
                    .animation(.easeOut(duration: 0.2), value: nameFocused)

                Text("This shows on the leaderboard")
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                nameFocused = true
            }
        }
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.locked.opacity(0.6))
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .shadow(
                        color: i == page ? Theme.accent.opacity(0.3) : .clear,
                        radius: 4
                    )
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.7), value: page)
        .padding(.bottom, 20)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button {
            Haptics.shared.waypoint()
            if page < 2 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 }
            } else {
                app.completeOnboarding(name: name.isEmpty ? "Player" : name)
            }
        } label: {
            HStack(spacing: 8) {
                Text(page < 2 ? "Continue" : "Let's zip")
                    .font(Theme.font(.headline))
                if page == 2 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // 3D bottom depth layer
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: 0xD94E30))
                        .offset(y: 4)

                    // Main button surface
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFF8566), Theme.accent, Theme.accent.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Top specular highlight
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .disabled(page == 2 && name.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(page == 2 && name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
    }
}

// MARK: - Onboard Page (Enhanced)

private struct OnboardPage<Icon: View>: View {
    @ViewBuilder let icon: Icon
    let title: String
    let subtitle: String
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var iconIn = false
    @State private var titleIn = false
    @State private var subtitleIn = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            icon
                .opacity(iconIn ? 1 : 0)
                .scaleEffect(reduceMotion ? 1 : (iconIn ? 1 : 0.6))

            Text(title)
                .font(Theme.font(.display))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .opacity(titleIn ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (titleIn ? 0 : 12))

            Text(subtitle)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .opacity(subtitleIn ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (subtitleIn ? 0 : 10))

            Spacer()
        }
        // Trigger off the active-selection binding so the entrance fires when the
        // page actually becomes visible — not when TabView pre-renders it off-screen.
        .onAppear { if isActive { animateIn() } }
        .onChange(of: isActive) { _, active in
            if active { animateIn() } else { resetIn() }
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.2)) {
                iconIn = true; titleIn = true; subtitleIn = true
            }
            return
        }
        // Staggered entrance: icon -> headline -> subtext (~100ms apart)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            iconIn = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            titleIn = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            subtitleIn = true
        }
    }

    private func resetIn() {
        iconIn = false
        titleIn = false
        subtitleIn = false
    }
}

// MARK: - Line Draw Demo

/// Hero illustration for the first slide: a single continuous line draws itself
/// through a 3×3 grid, hitting the numbered cells in order — then loops.
struct LineDrawDemo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let side: CGFloat = 132
    /// Snake path through every cell, in solve order.
    private let cells: [(Int, Int)] = [(0,0),(1,0),(2,0),(2,1),(1,1),(0,1),(0,2),(1,2),(2,2)]
    /// Path index -> displayed number (start, middle, end).
    private let numbered: [(index: Int, value: Int)] = [(0, 1), (4, 2), (8, 3)]
    /// Seconds for one full flow (fill → hold → drain).
    private let cycle: Double = 3.4

    var body: some View {
        let cell = side / 3
        let centers: [CGPoint] = cells.map {
            CGPoint(x: CGFloat($0.0) * cell + cell / 2,
                    y: CGFloat($0.1) * cell + cell / 2)
        }
        let lineWidth = cell * 0.30

        ZStack {
            // Grid cells
            ForEach(0..<9, id: \.self) { i in
                let c = i % 3, r = i / 3
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.boardLine, lineWidth: 1.5)
                    )
                    .frame(width: cell - 6, height: cell - 6)
                    .position(x: CGFloat(c) * cell + cell / 2,
                              y: CGFloat(r) * cell + cell / 2)
            }

            // The zip line, continuously flowing through 1 → 2 → 3.
            if reduceMotion {
                lineCanvas(centers: centers, from: 0, to: 1, lineWidth: lineWidth)
            } else {
                TimelineView(.animation) { timeline in
                    let span = trim(at: timeline.date)
                    lineCanvas(centers: centers, from: span.0, to: span.1, lineWidth: lineWidth)
                }
            }

            // Numbered target cells (static markers)
            ForEach(numbered, id: \.index) { badge in
                Text("\(badge.value)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Theme.accent))
                    .position(centers[badge.index])
            }
        }
        .frame(width: side, height: side)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .cardShadow()
    }

    private func lineCanvas(centers: [CGPoint], from: CGFloat, to: CGFloat, lineWidth: CGFloat) -> some View {
        Canvas { ctx, _ in
            var path = Path()
            path.move(to: centers[0])
            centers.dropFirst().forEach { path.addLine(to: $0) }
            ctx.stroke(
                path.trimmedPath(from: from, to: to),
                with: .color(Theme.accent),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: side, height: side)
    }

    /// Continuous loop: blank → head fills to full (1→2→3) → hold → tail drains → blank.
    private func trim(at date: Date) -> (CGFloat, CGFloat) {
        let p = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: cycle) / cycle   // 0...1
        switch p {
        case ..<0.55:                       // fill: head advances 0 → 1
            return (0, ease(p / 0.55))
        case ..<0.70:                       // hold on the full path
            return (0, 1)
        default:                            // drain: tail advances 0 → 1
            return (ease((p - 0.70) / 0.30), 1)
        }
    }

    /// Smoothstep for gentle ease-in / ease-out.
    private func ease(_ x: Double) -> CGFloat {
        let t = min(max(x, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }
}

// MARK: - Sparkle Background

/// Minimal floating particles for premium depth feel.
struct SparkleBackground: View {
    @State private var particles: [SparkleParticle] = []

    struct SparkleParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var duration: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                for p in particles {
                    let phase = sin(t / p.duration * .pi * 2)
                    let y = p.y * size.height + CGFloat(phase) * 20
                    let x = p.x * size.width
                    let alpha = p.opacity * (0.5 + 0.5 * abs(sin(t / p.duration * .pi)))
                    let rect = CGRect(
                        x: x - p.size / 2,
                        y: y - p.size / 2,
                        width: p.size,
                        height: p.size
                    )
                    ctx.fill(Circle().path(in: rect), with: .color(Theme.accent.opacity(alpha)))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { spawnParticles() }
    }

    private func spawnParticles() {
        particles = (0..<12).map { _ in
            SparkleParticle(
                x: CGFloat.random(in: 0.05...0.95),
                y: CGFloat.random(in: 0.1...0.9),
                size: CGFloat.random(in: 3...6),
                opacity: Double.random(in: 0.1...0.25),
                duration: Double.random(in: 3...6)
            )
        }
    }
}

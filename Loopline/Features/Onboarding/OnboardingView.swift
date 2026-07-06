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

    var body: some View {
        ZStack {
            // Subtle sparkle background
            SparkleBackground()
                .opacity(0.6)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        icon: { LogoMark(progress: 1).frame(width: 80, height: 80) },
                        title: "One line.\nEvery cell.",
                        subtitle: "Draw a single path through every square, hitting the numbers in order."
                    )
                    .tag(0)

                    OnboardPage(
                        icon: { DemoBoard() },
                        title: "It's a race.",
                        subtitle: "Every backtrack and hint counts. Solve clean, solve fast."
                    )
                    .tag(1)

                    OnboardPage(
                        icon: {
                            StreakFlameView(active: true)
                                .frame(width: 80, height: 80)
                        },
                        title: "Come back daily.",
                        subtitle: "A new puzzle drops every 24 hours. Keep your streak alive."
                    )
                    .tag(2)

                    namePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

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
                .offset(y: emojiFloat ? -6 : 6)
                .shadow(color: Theme.accent.opacity(0.15), radius: 12, y: 8)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: emojiFloat
                )
                .onAppear { emojiFloat = true }

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
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: nameFocused)

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
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.locked.opacity(0.6))
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .shadow(
                        color: i == page ? Theme.accent.opacity(0.3) : .clear,
                        radius: 4
                    )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
        .padding(.bottom, 20)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button {
            Haptics.shared.waypoint()
            if page < 3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 }
            } else {
                app.completeOnboarding(name: name.isEmpty ? "Player" : name)
            }
        } label: {
            HStack(spacing: 8) {
                Text(page < 3 ? "Continue" : "Let's zip")
                    .font(Theme.font(.headline))
                if page == 3 {
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
        .disabled(page == 3 && name.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(page == 3 && name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
    }
}

// MARK: - Onboard Page (Enhanced)

private struct OnboardPage<Icon: View>: View {
    @ViewBuilder let icon: Icon
    let title: String
    let subtitle: String
    @State private var contentVisible = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            icon
                .opacity(contentVisible ? 1 : 0)
                .scaleEffect(contentVisible ? 1 : 0.85)
                .offset(y: contentVisible ? 0 : 15)

            Text(title)
                .font(Theme.font(.display))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 10)

            Text(subtitle)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 8)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                contentVisible = true
            }
        }
        .onDisappear {
            contentVisible = false
        }
    }
}

// MARK: - Demo Board (kept exactly as-is)

struct DemoBoard: View {
    @State private var t: CGFloat = 0
    var body: some View {
        LogoMark(progress: t)
            .frame(width: 100, height: 100)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
            .cardShadow()
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { t = 1 }
            }
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

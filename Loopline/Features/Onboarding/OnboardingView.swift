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

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardPage(icon: { LogoMark(progress: 1).frame(width: 80, height: 80) },
                            title: "One line.\nEvery cell.",
                            subtitle: "Draw a single path through every square, hitting the numbers in order.")
                    .tag(0)
                OnboardPage(icon: { DemoBoard() },
                            title: "It's a race.",
                            subtitle: "Every backtrack and hint counts. Solve clean, solve fast.")
                    .tag(1)
                OnboardPage(icon: {
                    StreakFlameView(active: true).frame(width: 80, height: 80)
                }, title: "Come back daily.",
                            subtitle: "A new puzzle drops every 24 hours. Keep your streak alive.")
                    .tag(2)
                namePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy, value: page)

            pageDots
            primaryButton
        }
        .background(Theme.background)
    }

    private var namePage: some View {
        VStack(spacing: 24) {
            Text(app.profile.emoji).font(.system(size: 72))
            Text("What should we call you?")
                .font(Theme.font(.title))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            TextField("Your name", text: $name)
                .font(Theme.font(.headline))
                .multilineTextAlignment(.center)
                .focused($nameFocused)
                .padding(.vertical, 16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
                .cardShadow()
                .padding(.horizontal, 48)
        }
        .onAppear { nameFocused = true }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.locked)
                    .frame(width: i == page ? 24 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
        .padding(.bottom, 20)
    }

    private var primaryButton: some View {
        Button {
            if page < 3 { withAnimation { page += 1 } }
            else {
                app.completeOnboarding(name: name.isEmpty ? "Player" : name)
            }
        } label: {
            Text(page < 3 ? "Continue" : "Let's zip →")
                .font(Theme.font(.headline))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .disabled(page == 3 && name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

private struct OnboardPage<Icon: View>: View {
    @ViewBuilder let icon: Icon
    let title: String, subtitle: String
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            icon
            Text(title).font(Theme.font(.display))
                .foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(subtitle).font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Spacer()
        }
    }
}

/// Tiny 3×3 self-solving demo board that loops — teaches by showing.
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

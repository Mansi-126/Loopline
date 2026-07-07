//
//  ProfileView.swift
//  Loopline
//
//  Created by Mansi Gangani on 06/07/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var app: AppState
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showEmojiPicker = false
    @State private var showSettings = false
    @FocusState private var nameFieldFocused: Bool

    private let emojiOptions = [
        "🦊", "🐙", "🦉", "🐢", "🦋", "🐝",
        "🐼", "🦁", "🐯", "🐸", "🐵", "🦄",
        "🐶", "🐱", "🐰", "🐻", "🐨", "🐷",
        "🦈", "🐬", "🦜", "🐧", "🦀", "🐞",
        "🌟", "⚡️", "🔥", "💎", "🎯", "🚀"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with settings button
            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xE8E4DD))
                            .frame(width: 38, height: 38)
                            .offset(y: 2)
                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 38, height: 38)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .frame(width: 38, height: 38)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Avatar section
                    avatarSection
                        .padding(.top, 30)

                    // Name section
                    nameSection

                    // Stats section
                    statsSection

                    // Info section
                    infoSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Theme.background)
        .onAppear { draftName = app.profile.displayName }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(app)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showEmojiPicker.toggle()
                }
            } label: {
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    // 3D shadow
                    Circle()
                        .fill(.black.opacity(0.08))
                        .frame(width: 88, height: 88)
                        .offset(y: 6)
                        .blur(radius: 5)

                    // Main avatar circle
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(Theme.accent, lineWidth: 3)
                        )
                        .overlay(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.4), .clear],
                                        center: .init(x: 0.3, y: 0.25),
                                        startRadius: 0,
                                        endRadius: 35
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                    Text(app.profile.emoji)
                        .font(.system(size: 40))

                    // Edit badge
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                        .offset(x: 30, y: 30)
                }
            }
            .buttonStyle(.plain)

            Text(app.profile.displayName.isEmpty ? "Player" : app.profile.displayName)
                .font(Theme.font(.title))
                .foregroundStyle(Theme.ink)

            // Emoji picker grid
            if showEmojiPicker {
                emojiPicker
            }
        }
    }

    // MARK: - Emoji Picker

    private var emojiPicker: some View {
        VStack(spacing: 10) {
            Text("Choose Avatar")
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        selectEmoji(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 46, height: 46)
                            .background(
                                Circle()
                                    .fill(app.profile.emoji == emoji ? Theme.accentSoft : Theme.surface)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                app.profile.emoji == emoji ? Theme.accent : Theme.boardLine,
                                                lineWidth: app.profile.emoji == emoji ? 2 : 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.boardLine, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(spacing: 12) {
            if editingName {
                // Edit mode
                HStack(spacing: 12) {
                    TextField("Your name", text: $draftName)
                        .font(Theme.font(.body))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                        .focused($nameFieldFocused)

                    Button {
                        saveName()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Theme.accent, in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        editingName = false
                        draftName = app.profile.displayName
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                            .frame(width: 40, height: 40)
                            .background(Theme.surface, in: Circle())
                            .overlay(Circle().stroke(Theme.boardLine, lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .onAppear { nameFieldFocused = true }
            } else {
                // View mode — tap to edit
                Button {
                    draftName = app.profile.displayName
                    editingName = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                        Text("Edit Name")
                            .font(Theme.font(.body))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(app.profile.displayName.isEmpty ? "Not set" : app.profile.displayName)
                            .font(Theme.font(.body))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xE8E4DD))
                                .offset(y: 3)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.surface)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .clear],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 3)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                profileStat(icon: "star.fill", value: "\(app.progress.totalSolved)", label: "Solved", color: Theme.gold)
                profileStat(icon: "flame.fill", value: "\(app.streak.count)", label: "Streak", color: Theme.accent)
                profileStat(icon: "map.fill", value: "\(app.progress.highestUnlocked - 1)", label: "Cleared", color: Theme.success)
            }
        }
    }

    private func profileStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)

            Text(label)
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0xE8E4DD))
                    .offset(y: 3)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
            }
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 3)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 8) {
            infoRow(label: "Player ID", value: String(app.profile.id.uuidString.prefix(8)))
            infoRow(label: "Emoji", value: app.profile.emoji)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            Text(value)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surface)
        )
    }

    // MARK: - Actions

    private func saveName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        app.updateName(trimmed)
        editingName = false
    }

    private func selectEmoji(_ emoji: String) {
        app.updateEmoji(emoji)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showEmojiPicker = false
        }
    }
}

//
//  SettingsView.swift
//  Loopline
//
//  Created by Mansi Gangani on 06/07/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showTimer") private var showTimer = true
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.inkSecondary)
                Text("Settings")
                    .font(Theme.font(.title))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Gameplay section
                    settingsSection(title: "Gameplay") {
                        toggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "Haptics",
                            subtitle: "Vibration feedback while playing",
                            isOn: $hapticsEnabled,
                            color: Theme.accent
                        )

                        toggleRow(
                            icon: "stopwatch.fill",
                            title: "Show Timer",
                            subtitle: "Display elapsed time during puzzle",
                            isOn: $showTimer,
                            color: Theme.gold
                        )
                    }

                    // Data section
                    settingsSection(title: "Data") {
                        actionRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Sync Now",
                            subtitle: "Upload progress to cloud",
                            color: Theme.success
                        ) {
                            Task { await app.syncToCloud() }
                        }

                        actionRow(
                            icon: "trash.fill",
                            title: "Reset Progress",
                            subtitle: "Clear all levels and start over",
                            color: .red
                        ) {
                            showResetAlert = true
                        }
                    }

                    // About section
                    settingsSection(title: "About") {
                        infoRow(icon: "info.circle.fill", title: "Version", value: appVersion, color: Theme.inkSecondary)
                        infoRow(icon: "puzzlepiece.fill", title: "Puzzles", value: "200 levels", color: Theme.accent)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Theme.background)
        .alert("Reset Progress?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                app.resetProgress()
            }
        } message: {
            Text("This will clear all your completed levels, best times, and streak. This cannot be undone.")
        }
    }

    // MARK: - Section Container

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.inkSecondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: 0xE8E4DD))
                        .offset(y: 3)
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.surface)
                    RoundedRectangle(cornerRadius: 18)
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
    }

    // MARK: - Toggle Row

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(.body))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .tint(Theme.accent)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Action Row

    private func actionRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.font(.body))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.inkSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.ink)

            Spacer()

            Text(value)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

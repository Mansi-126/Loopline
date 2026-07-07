//
//  GameHUD.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct GameHUD: View {
    @ObservedObject var engine: GameEngine
    let onExit: () -> Void
    @AppStorage("showTimer") private var showTimer = true

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                // 3D close button
                Button(action: onExit) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xE8E4DD))
                            .frame(width: 40, height: 40)
                            .offset(y: 3)
                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .clear],
                                            startPoint: .top, endPoint: .center
                                        )
                                    )
                            )
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                // 3D timer pill (only if enabled)
                if showTimer {
                    ZStack {
                        Capsule()
                            .fill(Color(hex: 0xE8E4DD))
                            .frame(height: 38)
                            .offset(y: 3)
                        Capsule()
                            .fill(Theme.surface)
                            .frame(height: 38)
                        Text(engine.elapsed.clockString)
                            .font(Theme.font(.mono))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(engine.elapsed))
                    }
                    .frame(width: 100)

                    Spacer()
                }

                // Backtracks counter with depth
                ZStack {
                    Capsule()
                        .fill(Color(hex: 0xE8E4DD))
                        .offset(y: 3)
                    Capsule()
                        .fill(Theme.surface)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(engine.backtracks)")
                            .font(Theme.font(.caption))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
                .frame(width: 56, height: 36)
            }

            // 3D progress bar — inset track with raised fill
            ZStack(alignment: .leading) {
                // Inset track (carved into surface)
                Capsule()
                    .fill(Theme.boardLine)
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.black.opacity(0.04), .clear],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )

                // Raised fill bar with 3D highlight
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.85)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.35), .clear],
                                        startPoint: .top, endPoint: .center
                                    )
                                )
                                .padding(1)
                        )
                        .frame(width: max(8, geo.size.width * engine.fillProgress))
                        .shadow(color: Theme.accent.opacity(0.3), radius: 4, y: 2)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7),
                                   value: engine.fillProgress)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

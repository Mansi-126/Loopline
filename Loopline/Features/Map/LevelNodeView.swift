//
//  LevelNodeView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct LevelNodeView: View {
    enum NodeState { case locked, current, completed }

    let level: Level
    let state: NodeState
    let bestTime: TimeInterval?
    let isMilestone: Bool
    let xOffset: Double
    let action: () -> Void

    @State private var bounce = false
    @State private var glowPulse = false
    @State private var appeared = false

    private var nodeSize: CGFloat { isMilestone ? 86 : 72 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow ring for current level (3D ambient glow)
                if state == .current {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(glowPulse ? 0.3 : 0.1), .clear],
                                center: .center,
                                startRadius: nodeSize * 0.3,
                                endRadius: nodeSize * 0.8
                            )
                        )
                        .frame(width: nodeSize + 28, height: nodeSize + 28)
                }

                // 3D Depth pedestal (multiple layers for true 3D)
                Circle()
                    .fill(shadowColor.opacity(0.5))
                    .frame(width: nodeSize - 2, height: nodeSize - 2)
                    .offset(y: 8)
                    .blur(radius: 3)

                
                Circle()
                    .fill(shadowColor)
                    .frame(width: nodeSize, height: nodeSize)
                    .offset(y: 5)

                // Main 3D sphere node
                Circle()
                    .fill(fillGradient)
                    .frame(width: nodeSize, height: nodeSize)
                    // Top specular highlight (makes it look like a 3D sphere)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.45), .clear],
                                    center: .init(x: 0.35, y: 0.25),
                                    startRadius: 0,
                                    endRadius: nodeSize * 0.4
                                )
                            )
                    )
                    // Rim light (edge highlight for 3D depth)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear, .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .padding(1)
                    )
                    // Bottom shadow edge
                    .overlay(alignment: .bottom) {
                        Circle()
                            .trim(from: 0.6, to: 0.9)
                            .stroke(.black.opacity(0.15), lineWidth: 2)
                            .padding(1)
                    }

                // Content (icon/text)
                nodeContent
            }
            .overlay(alignment: .top) {
                if state == .current {
                    startLabel
                }
            }
            .overlay(alignment: .bottom) {
                if state == .completed, let t = bestTime {
                    timeLabel(t)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(state == .locked)
        .offset(x: xOffset)
        .padding(.vertical, isMilestone ? 22 : 18)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.7)
        .rotation3DEffect(
            .degrees(appeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05)) {
                appeared = true
            }
            if state == .current {
                bounce = true
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }

    // MARK: - Node Content

    @ViewBuilder
    private var nodeContent: some View {
        switch state {
        case .locked:
            VStack(spacing: 2) {
                Text("\(level.index)")
                    .font(.system(size: isMilestone ? 20 : 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: isMilestone ? 12 : 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }

        case .current:
            if isMilestone {
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: Theme.gold.opacity(0.5), radius: 4)
                    Text("\(level.index)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            } else {
                Text("\(level.index)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }

        case .completed:
            if isMilestone {
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(level.index)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            } else {
                Text("\(level.index)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }
        }
    }

    // MARK: - Start Label (3D floating badge)

    private var startLabel: some View {
        ZStack {
            // Shadow
            Capsule()
                .fill(.black.opacity(0.08))
                .frame(width: 58, height: 22)
                .offset(y: bounce ? -35 : -29)
                .blur(radius: 3)

            Text("START")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    ZStack {
                        Capsule().fill(Theme.surface)
                        // Top highlight
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    Capsule().stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
                .offset(y: bounce ? -38 : -32)
        }
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: bounce
        )
    }

    // MARK: - Time Label

    private func timeLabel(_ time: TimeInterval) -> some View {
        Text(time.clockString)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                ZStack {
                    Capsule().fill(Theme.surface)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
            .offset(y: 14)
    }

    // MARK: - Colors (3D gradients)

    private var fillGradient: some ShapeStyle {
        switch state {
        case .locked:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Theme.locked.opacity(0.9), Theme.locked, Color(hex: 0xC4BFB6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .current:
            return AnyShapeStyle(
                LinearGradient(
                    colors: isMilestone
                        ? [Theme.gold, Theme.accent, Theme.accent.opacity(0.9)]
                        : [Color(hex: 0xFF8566), Theme.accent, Color(hex: 0xE55A3A)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: isMilestone
                        ? [Theme.success, Color(hex: 0x2E8F5C), Color(hex: 0x267A4E)]
                        : [Color(hex: 0x4BC88A), Theme.success, Color(hex: 0x2E8F5C)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var shadowColor: Color {
        switch state {
        case .locked: return Color(hex: 0xB0AAA2)
        case .current: return Color(hex: 0xC44428)
        case .completed: return Color(hex: 0x247548)
        }
    }
}

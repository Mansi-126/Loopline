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
    let xOffset: Double
    let action: () -> Void

    @State private var bounce = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // "Depth" pedestal — the pressed-in Duolingo look.
                Circle().fill(shadowColor).offset(y: 6)
                Circle().fill(fillColor)
                    .overlay(content)
            }
            .frame(width: 76, height: 76)
            .overlay(alignment: .top) {
                if state == .current {
                    Text("START")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.surface, in: Capsule())
                        .cardShadow()
                        .offset(y: bounce ? -34 : -28)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: bounce)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(state == .locked)
        .offset(x: xOffset)
        .padding(.vertical, 18)
        .onAppear { bounce = true }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        case .current:
            Text("\(level.index)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        case .completed:
            VStack(spacing: 2) {
                Image(systemName: "checkmark").font(.system(size: 18, weight: .heavy))
                if let t = bestTime {
                    Text(t.clockString).font(.system(size: 10, weight: .bold, design: .monospaced))
                }
            }
            .foregroundStyle(.white)
        }
    }

    private var fillColor: Color {
        switch state {
        case .locked: Theme.locked
        case .current: Theme.accent
        case .completed: Theme.success
        }
    }
    private var shadowColor: Color {
        switch state {
        case .locked: Color(hex: 0xC4BFB6)
        case .current: Color(hex: 0xD94E30)
        case .completed: Color(hex: 0x2E8F5C)
        }
    }
}

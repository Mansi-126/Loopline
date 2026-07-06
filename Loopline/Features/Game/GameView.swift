//
//  GameView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var engine: GameEngine
    @State private var showBoard = false
    @State private var boardRotation: Double = -8

    init(level: Level) {
        _engine = StateObject(wrappedValue: GameEngine(level: level))
    }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(engine: engine, onExit: {
                withAnimation(.snappy) { app.route = .map }
            })

            Spacer()

            // 3D board entrance: rotates from slight perspective and scales in
            BoardView(engine: engine)
                .padding(.horizontal, 20)
                .scaleEffect(showBoard ? 1 : 0.85)
                .opacity(showBoard ? 1 : 0)
                .rotation3DEffect(
                    .degrees(showBoard ? 0 : boardRotation),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )

            Spacer()

            // 3D Control pills
            controls
        }
        .background(Theme.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                showBoard = true
                boardRotation = 0
            }
            engine.startTimer()
        }
        .onChange(of: engine.isSolved) { _, solved in
            guard solved else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                app.finish(result: engine.makeResult())
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            ControlPill3D(icon: "arrow.uturn.backward", label: "Undo") {
                if engine.path.count > 1 { engine.rewind(to: engine.path[engine.path.count - 2]) }
            }
            ControlPill3D(icon: "lightbulb.fill", label: "Hint", tint: Theme.gold) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { engine.useHint() }
            }
            ControlPill3D(icon: "arrow.counterclockwise", label: "Reset") {
                withAnimation(.snappy) { engine.reset() }
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - 3D Control Pill

struct ControlPill3D: View {
    let icon: String
    let label: String
    var tint: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(Theme.font(.caption))
            }
            .foregroundStyle(tint)
            .frame(width: 84, height: 64)
            .background(
                ZStack {
                    // Bottom layer (3D depth)
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: 0xE8E4DD))
                        .offset(y: 4)

                    // Main surface
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.surface)

                    // Top highlight
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// Keep old ControlPill name for backward compat if referenced elsewhere
typealias ControlPill = ControlPill3D

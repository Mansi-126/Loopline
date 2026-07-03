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

    init(level: Level) {
        _engine = StateObject(wrappedValue: GameEngine(level: level))
    }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(engine: engine, onExit: {
                withAnimation(.snappy) { app.route = .map }
            })
            Spacer()
            BoardView(engine: engine)
                .padding(.horizontal, 20)
                .scaleEffect(showBoard ? 1 : 0.9)
                .opacity(showBoard ? 1 : 0)
            Spacer()
            controls
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { showBoard = true }
            engine.startTimer()
        }
        .onChange(of: engine.isSolved) { _, solved in
            guard solved else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.1))   // savor the shimmer
                app.finish(result: engine.makeResult())
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            ControlPill(icon: "arrow.uturn.backward", label: "Undo") {
                if engine.path.count > 1 { engine.rewind(to: engine.path[engine.path.count - 2]) }
            }
            ControlPill(icon: "lightbulb.fill", label: "Hint", tint: Theme.gold) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { engine.useHint() }
            }
            ControlPill(icon: "arrow.counterclockwise", label: "Reset") {
                withAnimation(.snappy) { engine.reset() }
            }
        }
        .padding(.bottom, 32)
    }
}

struct ControlPill: View {
    let icon: String
    let label: String
    var tint: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(label).font(Theme.font(.caption))
            }
            .foregroundStyle(tint)
            .frame(width: 84, height: 64)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .buttonStyle(PressableButtonStyle())
    }
}

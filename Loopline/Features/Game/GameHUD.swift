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

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: onExit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(width: 40, height: 40)
                        .background(Theme.surface, in: Circle())
                        .cardShadow()
                }
                .buttonStyle(PressableButtonStyle())
                Spacer()
                Text(engine.elapsed.clockString)
                    .font(Theme.font(.mono))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(engine.elapsed))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward").font(.system(size: 12, weight: .bold))
                    Text("\(engine.backtracks)").font(Theme.font(.caption))
                }
                .foregroundStyle(Theme.inkSecondary)
                .frame(width: 40, height: 40)
            }
            // Fill progress bar — springy, coral, satisfying.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.boardLine)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(8, geo.size.width * engine.fillProgress))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7),
                                   value: engine.fillProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

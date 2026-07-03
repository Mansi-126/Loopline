//
//  ConfettiView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

/// Physics-based confetti on a Canvas: 120 particles with gravity, drag,
/// spin, and per-particle flutter. Cheap, GPU-composited, zero dependencies.
struct ConfettiView: View {
    private struct Particle {
        var x, y, vx, vy, spin, angle, size: Double
        var color: Color
        var shape: Int
    }

    @State private var particles: [Particle] = []
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                for p in particles {
                    let x = p.x * size.width + p.vx * t * 60 + sin(t * 3 + p.spin) * 8
                    let y = p.y * size.height + p.vy * t * 60 + 180 * t * t
                    guard y < size.height + 40 else { continue }
                    let angle = Angle(radians: p.angle + p.spin * t * 4)
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: angle)
                    // flutter: scale one axis with a sine for a tumbling look
                    c.scaleBy(x: 1, y: abs(sin(t * 5 + p.spin)))
                    let rect = CGRect(x: -p.size/2, y: -p.size/2, width: p.size, height: p.size * 0.6)
                    let path = p.shape == 0 ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    c.fill(path, with: .color(p.color))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { spawn() }
    }

    private func spawn() {
        let colors = [Theme.accent, Theme.gold, Theme.success, Color(hex: 0x5B8DEF), Color(hex: 0xB56FE8)]
        particles = (0..<120).map { _ in
            Particle(x: .random(in: 0.1...0.9), y: .random(in: -0.25 ... -0.05),
                     vx: .random(in: -1.2...1.2), vy: .random(in: 0.5...2.5),
                     spin: .random(in: -3...3), angle: .random(in: 0...(2 * .pi)),
                     size: .random(in: 7...13),
                     color: colors.randomElement()!, shape: Int.random(in: 0...1))
        }
    }
}

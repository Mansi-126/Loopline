//
//  BoardView.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var engine: GameEngine
    @State private var shaderClock = Date()
    @State private var winScale: CGFloat = 1
    @State private var boardTiltX: CGFloat = 0
    @State private var boardTiltY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let boardSide = min(geo.size.width, geo.size.height)
            let cell = boardSide / CGFloat(engine.puzzle.size)

            ZStack {
                // 3D elevated board background
                boardBackground(cell: cell)
                pathLayer(cell: cell)
                waypointLayer(cell: cell)
                if let hint = engine.hintFlash { hintLayer(hint, cell: cell) }
            }
            .frame(width: boardSide, height: boardSide)
            .scaleEffect(winScale)
            // 3D perspective tilt based on drag position
            .rotation3DEffect(
                .degrees(Double(boardTiltY) * 0.015),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.4
            )
            .rotation3DEffect(
                .degrees(Double(-boardTiltX) * 0.015),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.4
            )
            .modifier(ShakeEffect(shakes: engine.errorPulse ? 1 : 0))
            .gesture(dragGesture(cell: cell, geoSize: geo.size))
            .onChange(of: engine.isSolved) { _, solved in
                guard solved else { return }
                // 3D celebration: board tilts back then pops forward
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { winScale = 1.05 }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.2)) { winScale = 1 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    boardTiltX = 0
                    boardTiltY = 0
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Layers

    private func boardBackground(cell: CGFloat) -> some View {
        Canvas { ctx, size in
            let n = engine.puzzle.size
            let r: CGFloat = 24

            // Base shadow layer (creates 3D depth)
            let shadowRect = CGRect(x: 3, y: 6, width: size.width, height: size.height)
            ctx.fill(Path(roundedRect: shadowRect, cornerRadius: r),
                     with: .color(.black.opacity(0.06)))

            // Middle depth layer
            let midRect = CGRect(x: 1, y: 3, width: size.width, height: size.height)
            ctx.fill(Path(roundedRect: midRect, cornerRadius: r),
                     with: .color(.black.opacity(0.03)))

            // Main surface
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: r),
                     with: .color(Theme.surface))

            // Subtle top-edge highlight (3D bevel)
            var highlight = Path()
            highlight.move(to: CGPoint(x: r, y: 1.5))
            highlight.addLine(to: CGPoint(x: size.width - r, y: 1.5))
            ctx.stroke(highlight, with: .color(.white.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            // Grid lines
            var lines = Path()
            for i in 1..<n {
                let x = CGFloat(i) * cell
                lines.move(to: CGPoint(x: x, y: 8))
                lines.addLine(to: CGPoint(x: x, y: size.height - 8))
                lines.move(to: CGPoint(x: 8, y: x))
                lines.addLine(to: CGPoint(x: size.width - 8, y: x))
            }
            ctx.stroke(lines, with: .color(Theme.boardLine), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 28, y: 16)
    }

    private func pathLayer(cell: CGFloat) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(shaderClock)
            Canvas { ctx, size in
                guard engine.path.count > 1 else { return }
                var p = Path()
                p.move(to: center(engine.path[0], cell))
                for pt in engine.path.dropFirst() { p.addLine(to: center(pt, cell)) }

                // Outer glow for 3D ribbon effect
                ctx.stroke(p, with: .color(Theme.accent.opacity(0.3)),
                           style: StrokeStyle(lineWidth: cell * 0.72, lineCap: .round, lineJoin: .round))

                // Main path
                ctx.stroke(p, with: .color(Theme.accent),
                           style: StrokeStyle(lineWidth: cell * 0.58, lineCap: .round, lineJoin: .round))

                // Inner highlight for 3D tube effect
                ctx.stroke(p, with: .color(.white.opacity(0.25)),
                           style: StrokeStyle(lineWidth: cell * 0.2, lineCap: .round, lineJoin: .round))
            }
            .colorEffect(ShaderLibrary.pathFlow(
                .float(t), .float2(Float(cell * CGFloat(engine.puzzle.size)),
                                   Float(cell * CGFloat(engine.puzzle.size)))))
            .modifier(engine.isSolved
                ? AnyViewModifier { $0.colorEffect(ShaderLibrary.winShimmer(
                    .float(t), .float2(400, 400))) }
                : AnyViewModifier { $0 })
        }
        .allowsHitTesting(false)
    }

    private func waypointLayer(cell: CGFloat) -> some View {
        ForEach(Array(engine.puzzle.waypoints.enumerated()), id: \.offset) { i, pt in
            let visited = engine.path.contains(pt)
            ZStack {
                // 3D shadow beneath waypoint
                Circle()
                    .fill(.black.opacity(0.1))
                    .frame(width: cell * 0.68, height: cell * 0.68)
                    .offset(y: 3)
                    .blur(radius: 2)

                // Main circle with 3D gradient
                Circle()
                    .fill(
                        visited
                        ? LinearGradient(colors: [Theme.ink, Theme.ink.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Theme.surface, Color(hex: 0xF5F2ED)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 2.5))
                    // Inner highlight for 3D sphere look
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(visited ? 0.15 : 0.4), .clear],
                                    center: .init(x: 0.35, y: 0.3),
                                    startRadius: 0,
                                    endRadius: cell * 0.3
                                )
                            )
                    )

                Text("\(i + 1)")
                    .font(.system(size: cell * 0.34, weight: .heavy, design: .rounded))
                    .foregroundStyle(visited ? Theme.surface : Theme.ink)
            }
            .frame(width: cell * 0.72, height: cell * 0.72)
            .scaleEffect(visited ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: visited)
            .position(center(pt, cell))
            .onTapGesture {
                if visited {
                    engine.tapWaypoint(at: pt)
                }
            }
        }
    }

    private func hintLayer(_ hint: GridPoint, cell: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cell * 0.25)
                .fill(Theme.gold.opacity(0.2))
                .frame(width: cell * 0.9, height: cell * 0.9)
                .blur(radius: 4)

            RoundedRectangle(cornerRadius: cell * 0.25)
                .fill(Theme.gold.opacity(0.4))
                .frame(width: cell * 0.82, height: cell * 0.82)
                .overlay(
                    RoundedRectangle(cornerRadius: cell * 0.25)
                        .stroke(Theme.gold.opacity(0.6), lineWidth: 2)
                )
        }
        .position(center(hint, cell))
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }

    // MARK: - Input

    private func dragGesture(cell: CGFloat, geoSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let col = Int(value.location.x / cell)
                let row = Int(value.location.y / cell)
                let n = engine.puzzle.size
                guard (0..<n).contains(row), (0..<n).contains(col) else { return }
                let target = GridPoint(row: row, col: col)

                // Update 3D tilt based on touch position
                let centerX = geoSize.width / 2
                let centerY = geoSize.height / 2
                withAnimation(.interactiveSpring(response: 0.15)) {
                    boardTiltX = value.location.x - centerX
                    boardTiltY = value.location.y - centerY
                }

                bridge(to: target)
            }
            .onEnded { _ in
                // Spring back to neutral
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    boardTiltX = 0
                    boardTiltY = 0
                }
            }
    }

    private func bridge(to target: GridPoint) {
        guard let head = engine.path.last else { return }
        if target == head { return }
        if target.isAdjacent(to: head) || engine.path.suffix(2).first == target {
            engine.visit(target); return
        }
        // Try tap-to-rewind
        if engine.path.contains(target) { engine.rewind(to: target); return }
        // Walk one axis then the other (L-shaped interpolation)
        var cursor = head
        while cursor != target {
            var next = cursor
            if cursor.row != target.row { next.row += cursor.row < target.row ? 1 : -1 }
            else { next.col += cursor.col < target.col ? 1 : -1 }
            guard engine.visit(next) else { break }
            cursor = next
        }
    }

    private func center(_ p: GridPoint, _ cell: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(p.col) * cell + cell / 2, y: CGFloat(p.row) * cell + cell / 2)
    }
}

/// Horizontal shake for invalid moves.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat { get { shakes } set { shakes = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(shakes * .pi * 4), y: 0))
    }
}

struct AnyViewModifier: ViewModifier {
    let transform: (AnyView) -> any View
    init(@ViewBuilder _ transform: @escaping (AnyView) -> some View) {
        self.transform = { AnyView(transform($0)) }
    }
    func body(content: Content) -> some View { AnyView(transform(AnyView(content))) }
}

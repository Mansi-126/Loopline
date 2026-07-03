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

    var body: some View {
        GeometryReader { geo in
            let boardSide = min(geo.size.width, geo.size.height)
            let cell = boardSide / CGFloat(engine.puzzle.size)

            ZStack {
                boardBackground(cell: cell)
                pathLayer(cell: cell)
                waypointLayer(cell: cell)
                if let hint = engine.hintFlash { hintLayer(hint, cell: cell) }
            }
            .frame(width: boardSide, height: boardSide)
            .scaleEffect(winScale)
            .modifier(ShakeEffect(shakes: engine.errorPulse ? 1 : 0))
            .gesture(dragGesture(cell: cell))
            .onChange(of: engine.isSolved) { _, solved in
                guard solved else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { winScale = 1.04 }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) { winScale = 1 }
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
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: r),
                     with: .color(Theme.surface))
            var lines = Path()
            for i in 1..<n {
                let x = CGFloat(i) * cell
                lines.move(to: CGPoint(x: x, y: 8)); lines.addLine(to: CGPoint(x: x, y: size.height - 8))
                lines.move(to: CGPoint(x: 8, y: x)); lines.addLine(to: CGPoint(x: size.width - 8, y: x))
            }
            ctx.stroke(lines, with: .color(Theme.boardLine), lineWidth: 1.5)
        }
        .cardShadow()
    }

    private func pathLayer(cell: CGFloat) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(shaderClock)
            Canvas { ctx, size in
                guard engine.path.count > 1 else { return }
                var p = Path()
                p.move(to: center(engine.path[0], cell))
                for pt in engine.path.dropFirst() { p.addLine(to: center(pt, cell)) }
                ctx.stroke(p, with: .color(Theme.accent),
                           style: StrokeStyle(lineWidth: cell * 0.62, lineCap: .round, lineJoin: .round))
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
                Circle()
                    .fill(visited ? Theme.ink : Theme.surface)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 2.5))
                Text("\(i + 1)")
                    .font(.system(size: cell * 0.34, weight: .heavy, design: .rounded))
                    .foregroundStyle(visited ? Theme.surface : Theme.ink)
            }
            .frame(width: cell * 0.72, height: cell * 0.72)
            .scaleEffect(visited ? 1.0 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: visited)
            .position(center(pt, cell))
            .allowsHitTesting(false)
        }
    }

    private func hintLayer(_ hint: GridPoint, cell: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cell * 0.25)
            .fill(Theme.gold.opacity(0.35))
            .frame(width: cell * 0.86, height: cell * 0.86)
            .position(center(hint, cell))
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
    }

    // MARK: - Input

    private func dragGesture(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let col = Int(value.location.x / cell)
                let row = Int(value.location.y / cell)
                let n = engine.puzzle.size
                guard (0..<n).contains(row), (0..<n).contains(col) else { return }
                let target = GridPoint(row: row, col: col)
                // Bridge diagonal jumps by stepping through intermediate cells,
                // so fast swipes never break the line.
                bridge(to: target)
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

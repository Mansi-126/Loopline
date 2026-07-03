//
//  PuzzleGenerator.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

/// Generates Zip puzzles by carving a random Hamiltonian path through the
/// grid (randomized DFS with a Warnsdorff-style heuristic — always try the
/// most-constrained neighbor first, which makes generation near-instant
/// even for 8×8), then dropping numbered waypoints along the path.
enum PuzzleGenerator {

    static func generate(level: Level) -> Puzzle {
        var rng = SeededRNG(seed: level.seed)
        let path = hamiltonianPath(size: level.size, rng: &rng)
        let waypoints = placeWaypoints(on: path, count: level.waypointCount, rng: &rng)
        return Puzzle(size: level.size, solution: path, waypoints: waypoints)
    }

    private static func hamiltonianPath(size: Int, rng: inout SeededRNG) -> [GridPoint] {
        let total = size * size
        // Start from a random edge cell — paths that start on edges look better.
        var edges: [GridPoint] = []
        for r in 0..<size { for c in 0..<size where r == 0 || c == 0 || r == size-1 || c == size-1 {
            edges.append(GridPoint(row: r, col: c))
        }}
        while true {
            let start = edges.randomElement(using: &rng)!
            var visited = Set([start]), path = [start]
            if extend(&path, &visited, size: size, total: total, rng: &rng) { return path }
        }
    }

    private static func extend(_ path: inout [GridPoint], _ visited: inout Set<GridPoint>,
                               size: Int, total: Int, rng: inout SeededRNG,
                               depthBudget: Int = 500_000) -> Bool {
        var budget = depthBudget
        func degree(_ p: GridPoint) -> Int {
            neighbors(p, size).filter { !visited.contains($0) }.count
        }
        func recurse() -> Bool {
            budget -= 1
            if budget < 0 { return false }
            if path.count == total { return true }
            let current = path.last!
            var options = neighbors(current, size).filter { !visited.contains($0) }
            options.shuffle(using: &rng)
            options.sort { degree($0) < degree($1) }   // Warnsdorff
            for next in options {
                path.append(next); visited.insert(next)
                if recurse() { return true }
                path.removeLast(); visited.remove(next)
            }
            return false
        }
        return recurse()
    }

    private static func neighbors(_ p: GridPoint, _ size: Int) -> [GridPoint] {
        [(-1,0),(1,0),(0,-1),(0,1)].compactMap { d in
            let q = GridPoint(row: p.row + d.0, col: p.col + d.1)
            return (0..<size).contains(q.row) && (0..<size).contains(q.col) ? q : nil
        }
    }

    /// Waypoints: endpoints are always 1 and N; the rest are spread with
    /// jitter so numbers never bunch up (uneven spacing = feels handcrafted).
    private static func placeWaypoints(on path: [GridPoint], count: Int,
                                       rng: inout SeededRNG) -> [GridPoint] {
        guard count >= 2 else { return [path.first!, path.last!] }
        var indices: Set<Int> = [0, path.count - 1]
        let segment = Double(path.count - 1) / Double(count - 1)
        for i in 1..<(count - 1) {
            let base = Double(i) * segment
            let jitter = Double.random(in: -segment/3...segment/3, using: &rng)
            var idx = Int((base + jitter).rounded())
            idx = max(1, min(path.count - 2, idx))
            while indices.contains(idx) { idx += 1 }
            indices.insert(idx)
        }
        return indices.sorted().map { path[$0] }
    }
}

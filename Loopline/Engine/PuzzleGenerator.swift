//
//  PuzzleGenerator.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

/// Generates Zip puzzles by producing a random Hamiltonian path through the
/// grid, then dropping numbered waypoints along the path.
///
/// The path is generated with the "backbite" algorithm: start from a simple
/// boustrophedon (snake) path that already covers every cell, then repeatedly
/// apply endpoint "bite" moves that reverse a prefix/suffix of the path. Every
/// intermediate state is a valid Hamiltonian path, so generation runs in
/// guaranteed linear time with no backtracking — unlike a DFS carve, which can
/// stall for many seconds on odd-celled grids (5×5, 7×7, 9×9).
enum PuzzleGenerator {

    static func generate(level: Level) -> Puzzle {
        var rng = SeededRNG(seed: level.seed)
        let path = hamiltonianPath(size: level.size, rng: &rng)
        let waypoints = placeWaypoints(on: path, count: level.waypointCount, rng: &rng)
        return Puzzle(size: level.size, solution: path, waypoints: waypoints)
    }

    private static func hamiltonianPath(size n: Int, rng: inout SeededRNG) -> [GridPoint] {
        // Seed with a boustrophedon snake — a trivially valid Hamiltonian path.
        var path: [GridPoint] = []
        path.reserveCapacity(n * n)
        for r in 0..<n {
            let cols = r % 2 == 0 ? Array(0..<n) : Array((0..<n).reversed())
            for c in cols { path.append(GridPoint(row: r, col: c)) }
        }

        // Track each cell's current position so we can locate a neighbor in O(1).
        var pos: [GridPoint: Int] = [:]
        for (i, p) in path.enumerated() { pos[p] = i }

        // Mixing steps: proportional to area gives a well-scrambled path.
        let moves = n * n * 10
        for _ in 0..<moves {
            let useHead = Bool.random(using: &rng)
            let endpoint = useHead ? path[0] : path[path.count - 1]
            let candidates = neighbors(endpoint, n).shuffled(using: &rng)

            // Pick a neighbor that isn't already the endpoint's path-neighbor
            // (biting into it would be a no-op).
            guard let w = candidates.first(where: { neighbor in
                guard let k = pos[neighbor] else { return false }
                return useHead ? k != 1 : k != path.count - 2
            }) else { continue }

            guard let k = pos[w] else { continue }
            if useHead {
                // Reverse prefix [0..<k]; joins endpoint to its chosen neighbor.
                path[0..<k].reverse()
                for i in 0..<k { pos[path[i]] = i }
            } else {
                // Reverse suffix (k..<end].
                path[(k + 1)...].reverse()
                for i in (k + 1)..<path.count { pos[path[i]] = i }
            }
        }
        return path
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
        guard !path.isEmpty else { return [] }
        guard count >= 2 else {
            return [path[0], path[path.count - 1]]
        }
        var indices: Set<Int> = [0, path.count - 1]
        let segment = Double(path.count - 1) / Double(count - 1)
        for i in 1..<(count - 1) {
            let base = Double(i) * segment
            let jitter = Double.random(in: -segment/3...segment/3, using: &rng)
            var idx = Int((base + jitter).rounded())
            idx = max(1, min(path.count - 2, idx))
            // Advance to next available slot, but stay within bounds
            while indices.contains(idx) && idx < path.count - 1 { idx += 1 }
            if idx < path.count - 1 {
                indices.insert(idx)
            }
        }
        return indices.sorted().map { path[$0] }
    }
}

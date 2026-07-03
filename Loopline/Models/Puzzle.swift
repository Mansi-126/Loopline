//
//  Puzzle.swift
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

import Foundation

struct GridPoint: Hashable, Codable {
    var row: Int, col: Int
    func isAdjacent(to other: GridPoint) -> Bool {
        abs(row - other.row) + abs(col - other.col) == 1
    }
}

/// A Zip puzzle: an n×n grid, a hidden Hamiltonian-path solution,
/// and numbered waypoints that must be visited in order.
struct Puzzle {
    let size: Int
    let solution: [GridPoint]          // full Hamiltonian path
    let waypoints: [GridPoint]         // waypoints[i] must be i+1-th number hit
    var cellCount: Int { size * size }

    func waypointNumber(at point: GridPoint) -> Int? {
        waypoints.firstIndex(of: point).map { $0 + 1 }
    }
}

struct GameResult: Equatable {
    let level: Level
    let time: TimeInterval
    let backtracks: Int
    let hintsUsed: Int
    let solvedAt: Date

    /// LinkedIn-style score: time is primary; backtracks & hints are tiebreak penalties.
    var score: Int {
        max(0, 100_000 - Int(time * 100) - backtracks * 500 - hintsUsed * 3000)
    }
}
